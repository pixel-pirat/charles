defmodule VisoBackend.Chat do
  @moduledoc """
  Real direct-messaging between signed-in users: conversation list,
  message history, sending (text/media/replies/link previews),
  reactions, edits, deletes, forwarding, read/delivered receipts,
  blocking, muting, pinning, archiving, starring. Mirrors the old
  vibe_server's ChatEndpoint. `conversation_topic/2` ties this to the
  real-time layer: both participants join the same deterministically-
  derived Channel topic, so broadcasting there reaches both of them.
  """

  import Ecto.Query
  alias VisoBackend.{Accounts, Repo}

  alias VisoBackend.Chat.{
    ArchivedConversation,
    BlockedUser,
    Message,
    MessageReaction,
    MutedConversation,
    PinnedConversation,
    StarredMessage
  }

  alias VisoBackendWeb.{Endpoint, Presence}

  @url_pattern ~r/https?:\/\/[^\s]+/

  @doc """
  The channel topic both participants of a 1:1 chat join. Always
  sorts the two ids so the same pair produces the same topic
  regardless of who connects first — e.g. {5, 2} and {2, 5} both give
  "room:2-5".
  """
  def conversation_topic(user_id_a, user_id_b) do
    [a, b] = Enum.sort([user_id_a, user_id_b])
    "room:#{a}-#{b}"
  end

  @doc "Whether `user_id` is one of the two participants encoded in `room_id`."
  def topic_includes_user?(room_id, user_id) do
    room_id
    |> String.split("-")
    |> Enum.member?(to_string(user_id))
  end

  @doc "Whether `user_id` is currently connected to the app at all (lobby presence)."
  def user_online?(user_id) do
    Presence.list("lobby") |> Map.has_key?(to_string(user_id))
  end

  # -------------------------------------------------------
  # Conversations list
  # -------------------------------------------------------

  @doc """
  Returns the signed-in user's conversations, most recent first, with
  pinned ones pinned to the top. Excludes archived conversations — see
  `get_archived_conversations/1`.
  """
  def list_conversations(user_id), do: build_conversation_summaries(user_id, false)

  @doc "Returns only the signed-in user's archived conversations."
  def get_archived_conversations(user_id), do: build_conversation_summaries(user_id, true)

  defp build_conversation_summaries(user_id, archived_only?) do
    messages =
      from(m in Message,
        where: m.sender_id == ^user_id or m.recipient_id == ^user_id,
        order_by: [desc: m.inserted_at],
        limit: 500
      )
      |> Repo.all()

    {last_by_partner, unread_by_partner} =
      Enum.reduce(messages, {%{}, %{}}, fn message, {last_acc, unread_acc} ->
        is_mine = message.sender_id == user_id
        partner_id = if is_mine, do: message.recipient_id, else: message.sender_id
        hidden_at = if is_mine, do: message.hidden_for_sender, else: message.hidden_for_recipient

        last_acc =
          if is_nil(hidden_at) do
            Map.put_new(last_acc, partner_id, message)
          else
            last_acc
          end

        unread_acc =
          if not is_mine and is_nil(message.read_at) and is_nil(message.hidden_for_recipient) do
            Map.update(unread_acc, partner_id, 1, &(&1 + 1))
          else
            unread_acc
          end

        {last_acc, unread_acc}
      end)

    archived_ids = conversation_flag_ids(ArchivedConversation, user_id, :archived_user_id)
    muted_ids = conversation_flag_ids(MutedConversation, user_id, :muted_user_id)
    pinned_ids = conversation_flag_ids(PinnedConversation, user_id, :pinned_user_id)

    summaries =
      for {partner_id, last_message} <- last_by_partner,
          MapSet.member?(archived_ids, partner_id) == archived_only? do
        profile = Accounts.get_user(partner_id)
        is_deleted = not is_nil(last_message.deleted_at)

        preview_text =
          cond do
            is_deleted -> "This message was deleted"
            last_message.text != "" -> last_message.text
            true -> media_label(last_message.media_type)
          end

        %{
          partner_id: partner_id,
          partner_name: profile && Accounts.display_name(profile),
          partner_username: profile && profile.username,
          partner_avatar_url: profile && profile.image_url,
          last_message_text: preview_text,
          last_message_media_type: if(is_deleted, do: nil, else: last_message.media_type),
          last_message_at: last_message.inserted_at,
          last_message_is_mine: last_message.sender_id == user_id,
          unread_count: Map.get(unread_by_partner, partner_id, 0),
          partner_is_online: user_online?(partner_id),
          is_muted: MapSet.member?(muted_ids, partner_id),
          is_pinned: MapSet.member?(pinned_ids, partner_id)
        }
      end

    Enum.sort(summaries, fn a, b ->
      cond do
        not archived_only? and a.is_pinned != b.is_pinned -> a.is_pinned
        true -> DateTime.compare(a.last_message_at, b.last_message_at) != :lt
      end
    end)
  end

  defp conversation_flag_ids(schema, user_id, other_field) do
    from(t in schema, where: t.user_id == ^user_id, select: field(t, ^other_field))
    |> Repo.all()
    |> MapSet.new()
  end

  # -------------------------------------------------------
  # Blocking
  # -------------------------------------------------------

  def block_user(user_id, user_id), do: {:error, :cannot_block_self}

  def block_user(blocker_id, blocked_id) do
    case Repo.get_by(BlockedUser, blocker_id: blocker_id, blocked_id: blocked_id) do
      nil -> Repo.insert(%BlockedUser{blocker_id: blocker_id, blocked_id: blocked_id})
      _ -> {:ok, :already_blocked}
    end
  end

  def unblock_user(blocker_id, blocked_id) do
    case Repo.get_by(BlockedUser, blocker_id: blocker_id, blocked_id: blocked_id) do
      nil -> :ok
      row -> Repo.delete(row)
    end

    :ok
  end

  def have_i_blocked?(blocker_id, blocked_id) do
    Repo.exists?(from t in BlockedUser, where: t.blocker_id == ^blocker_id and t.blocked_id == ^blocked_id)
  end

  @doc "Whether `user_id` can currently message `partner_id` — false if either has blocked the other."
  def can_message?(user_id, partner_id), do: not blocked_either_way?(user_id, partner_id)

  defp blocked_either_way?(a, b) do
    Repo.exists?(
      from t in BlockedUser,
        where: (t.blocker_id == ^a and t.blocked_id == ^b) or (t.blocker_id == ^b and t.blocked_id == ^a)
    )
  end

  @doc "The profiles of everyone `user_id` has blocked, most recently blocked first."
  def get_blocked_users(user_id) do
    from(t in BlockedUser, where: t.blocker_id == ^user_id, order_by: [desc: t.inserted_at])
    |> Repo.all()
    |> Enum.map(&Accounts.get_user(&1.blocked_id))
    |> Enum.filter(& &1)
  end

  # -------------------------------------------------------
  # Mute / pin / archive
  # -------------------------------------------------------

  def mute_conversation(user_id, partner_id), do: toggle_on(MutedConversation, user_id: user_id, muted_user_id: partner_id)
  def unmute_conversation(user_id, partner_id), do: toggle_off(MutedConversation, user_id: user_id, muted_user_id: partner_id)
  def pin_conversation(user_id, partner_id), do: toggle_on(PinnedConversation, user_id: user_id, pinned_user_id: partner_id)
  def unpin_conversation(user_id, partner_id), do: toggle_off(PinnedConversation, user_id: user_id, pinned_user_id: partner_id)

  def archive_conversation(user_id, partner_id),
    do: toggle_on(ArchivedConversation, user_id: user_id, archived_user_id: partner_id)

  def unarchive_conversation(user_id, partner_id),
    do: toggle_off(ArchivedConversation, user_id: user_id, archived_user_id: partner_id)

  defp toggle_on(schema, fields) do
    case Repo.get_by(schema, fields) do
      nil -> Repo.insert!(struct!(schema, fields))
      _ -> :ok
    end

    :ok
  end

  defp toggle_off(schema, fields) do
    case Repo.get_by(schema, fields) do
      nil -> :ok
      row -> Repo.delete(row)
    end

    :ok
  end

  # -------------------------------------------------------
  # Starred messages
  # -------------------------------------------------------

  def star_message(user_id, message_id), do: toggle_on(StarredMessage, user_id: user_id, message_id: message_id)
  def unstar_message(user_id, message_id), do: toggle_off(StarredMessage, user_id: user_id, message_id: message_id)

  def get_starred_message_ids(user_id) do
    from(t in StarredMessage, where: t.user_id == ^user_id, select: t.message_id)
    |> Repo.all()
  end

  @doc "Full, resolved views of every message `user_id` has starred, most recently starred first."
  def get_starred_messages(user_id) do
    rows =
      from(t in StarredMessage, where: t.user_id == ^user_id, order_by: [desc: t.inserted_at])
      |> Repo.all()

    if rows == [] do
      []
    else
      message_ids = Enum.map(rows, & &1.message_id)
      messages = from(m in Message, where: m.id in ^message_ids) |> Repo.all()
      views = to_views(messages) |> Map.new(&{&1.id, &1})

      rows |> Enum.map(&Map.get(views, &1.message_id)) |> Enum.filter(& &1)
    end
  end

  # -------------------------------------------------------
  # Messages
  # -------------------------------------------------------

  @doc """
  Returns the message history with `partner_id`, oldest first, with
  media, reply previews and reactions resolved. Also opportunistically
  marks any of the partner's messages as delivered (and broadcasts
  those updates).
  """
  def list_messages(user_id, partner_id, limit \\ 100) do
    messages =
      from(m in Message,
        where:
          (m.sender_id == ^user_id and m.recipient_id == ^partner_id) or
            (m.sender_id == ^partner_id and m.recipient_id == ^user_id),
        order_by: [desc: m.inserted_at],
        limit: ^limit
      )
      |> Repo.all()

    visible =
      Enum.filter(messages, fn m ->
        hidden_at = if m.sender_id == user_id, do: m.hidden_for_sender, else: m.hidden_for_recipient
        is_nil(hidden_at)
      end)

    to_mark_delivered =
      Enum.filter(visible, &(&1.recipient_id == user_id and is_nil(&1.delivered_at)))

    if to_mark_delivered != [] do
      now = DateTime.utc_now() |> DateTime.truncate(:second)
      ids = Enum.map(to_mark_delivered, & &1.id)
      from(m in Message, where: m.id in ^ids) |> Repo.update_all(set: [delivered_at: now])

      ids
      |> then(&from(m in Message, where: m.id in ^&1))
      |> Repo.all()
      |> to_views()
      |> Enum.each(&broadcast_update/1)
    end

    visible |> Enum.reverse() |> to_views()
  end

  @doc """
  Sends a message to `recipient_id`. `media_url`/`media_type` should
  already be uploaded via `VisoBackend.Media.upload/3`. A message
  needs text or an attachment (or both, e.g. a captioned photo).
  """
  def send_message(sender_id, recipient_id, attrs) when is_map(attrs) do
    cond do
      recipient_id == sender_id ->
        {:error, :cannot_message_self}

      blocked_either_way?(sender_id, recipient_id) ->
        {:error, :blocked}

      true ->
        %Message{}
        |> Message.changeset(Map.merge(attrs, %{"sender_id" => sender_id, "recipient_id" => recipient_id}))
        |> Repo.insert()
        |> case do
          {:ok, message} ->
            view = to_view(message)
            broadcast!(sender_id, recipient_id, "new_message", view)
            maybe_fetch_link_preview(message)
            {:ok, view}

          error ->
            error
        end
    end
  end

  @doc "Re-sends `message_id`'s content (text/media) to `to_recipient_id`."
  def forward_message(user_id, message_id, to_recipient_id) do
    with %Message{} = original <- Repo.get(Message, message_id),
         true <- original.sender_id == user_id or original.recipient_id == user_id,
         true <- is_nil(original.deleted_at) do
      send_message(user_id, to_recipient_id, %{
        "text" => original.text,
        "media_url" => original.media_url,
        "media_type" => original.media_type
      })
    else
      _ -> {:error, :not_found}
    end
  end

  @doc "Edits the text of a message the signed-in user sent."
  def edit_message(user_id, message_id, new_text) do
    with %Message{} = message <- Repo.get(Message, message_id),
         true <- message.sender_id == user_id,
         true <- is_nil(message.deleted_at),
         trimmed <- String.trim(new_text),
         true <- trimmed != "" do
      message
      |> Ecto.Changeset.change(text: trimmed, edited_at: DateTime.utc_now() |> DateTime.truncate(:second))
      |> Repo.update()
      |> case do
        {:ok, updated} ->
          view = to_view(updated)
          broadcast_update(view)
          {:ok, view}

        error ->
          error
      end
    else
      _ -> {:error, :not_found}
    end
  end

  @doc """
  Deletes a message for everyone — only the sender can do this. Clears
  the content; the client renders a "message deleted" placeholder.
  """
  def delete_message_for_everyone(user_id, message_id) do
    with %Message{} = message <- Repo.get(Message, message_id),
         true <- message.sender_id == user_id do
      message
      |> Ecto.Changeset.change(
        deleted_at: DateTime.utc_now() |> DateTime.truncate(:second),
        text: "",
        media_url: nil,
        media_type: nil
      )
      |> Repo.update()
      |> case do
        {:ok, updated} ->
          view = to_view(updated)
          broadcast_update(view)
          {:ok, view}

        error ->
          error
      end
    else
      _ -> {:error, :not_found}
    end
  end

  @doc "Hides a message from the signed-in user's view only; the other party still sees it normally."
  def delete_message_for_me(user_id, message_id) do
    case Repo.get(Message, message_id) do
      nil ->
        :ok

      message ->
        now = DateTime.utc_now() |> DateTime.truncate(:second)

        cond do
          message.sender_id == user_id ->
            message |> Ecto.Changeset.change(hidden_for_sender: now) |> Repo.update()

          message.recipient_id == user_id ->
            message |> Ecto.Changeset.change(hidden_for_recipient: now) |> Repo.update()

          true ->
            :ok
        end

        :ok
    end
  end

  @doc """
  Sets `user_id`'s reaction on `message_id` to `emoji`. Reacting with
  the same emoji again removes it; a different emoji replaces it.
  """
  def react_to_message(user_id, message_id, emoji) do
    with %Message{} = message <- Repo.get(Message, message_id),
         true <- message.sender_id == user_id or message.recipient_id == user_id do
      case Repo.get_by(MessageReaction, message_id: message_id, user_id: user_id) do
        nil ->
          Repo.insert!(%MessageReaction{message_id: message_id, user_id: user_id, emoji: emoji})

        %{emoji: ^emoji} = existing ->
          Repo.delete!(existing)

        existing ->
          existing |> Ecto.Changeset.change(emoji: emoji) |> Repo.update!()
      end

      view = to_view(message)
      broadcast_update(view)
      {:ok, view}
    else
      _ -> {:error, :not_found}
    end
  end

  @doc "Marks all messages from `partner_id` to the signed-in user as read."
  def mark_conversation_read(user_id, partner_id) do
    unread =
      from(m in Message,
        where: m.sender_id == ^partner_id and m.recipient_id == ^user_id and is_nil(m.read_at)
      )
      |> Repo.all()

    if unread != [] do
      now = DateTime.utc_now() |> DateTime.truncate(:second)
      ids = Enum.map(unread, & &1.id)
      from(m in Message, where: m.id in ^ids) |> Repo.update_all(set: [read_at: now])

      ids
      |> then(&from(m in Message, where: m.id in ^&1))
      |> Repo.all()
      |> to_views()
      |> Enum.each(&broadcast_update/1)
    end

    :ok
  end

  defp media_label("image"), do: "📷 Photo"
  defp media_label("video"), do: "🎥 Video"
  defp media_label("audio"), do: "🎤 Voice message"
  defp media_label("file"), do: "📄 Document"
  defp media_label(_), do: "Sent an attachment"

  defp broadcast!(user_a, user_b, event, view) do
    Endpoint.broadcast!(conversation_topic(user_a, user_b), event, view)
  end

  defp broadcast_update(view) do
    Endpoint.broadcast!(conversation_topic(view.sender_id, view.recipient_id), "message_updated", view)
  end

  defp to_view(%Message{} = message), do: to_views([message]) |> hd()

  defp to_views([]), do: []

  defp to_views(messages) do
    message_ids = Enum.map(messages, & &1.id)

    reactions_by_message =
      from(r in MessageReaction, where: r.message_id in ^message_ids)
      |> Repo.all()
      |> Enum.group_by(& &1.message_id)

    reply_ids = messages |> Enum.map(& &1.reply_to_message_id) |> Enum.filter(& &1)

    replied_by_id =
      if reply_ids == [] do
        %{}
      else
        from(m in Message, where: m.id in ^reply_ids) |> Repo.all() |> Map.new(&{&1.id, &1})
      end

    Enum.map(messages, fn m ->
      is_deleted = not is_nil(m.deleted_at)

      reactions =
        (reactions_by_message[m.id] || [])
        |> Enum.map(&%{user_id: &1.user_id, emoji: &1.emoji})

      reply_to = m.reply_to_message_id && replied_by_id[m.reply_to_message_id]
      reply_deleted = reply_to && not is_nil(reply_to.deleted_at)

      %{
        id: m.id,
        sender_id: m.sender_id,
        recipient_id: m.recipient_id,
        text: if(is_deleted, do: "", else: m.text),
        media_url: if(is_deleted, do: nil, else: m.media_url),
        media_type: if(is_deleted, do: nil, else: m.media_type),
        created_at: m.inserted_at,
        delivered_at: m.delivered_at,
        read_at: m.read_at,
        edited_at: m.edited_at,
        is_deleted: is_deleted,
        reply_to_message_id: m.reply_to_message_id,
        reply_to_sender_id: reply_to && reply_to.sender_id,
        reply_preview_text:
          cond do
            is_nil(reply_to) -> nil
            reply_deleted -> "This message was deleted"
            true -> reply_to.text
          end,
        reply_preview_media_type: if(reply_to && not reply_deleted, do: reply_to.media_type),
        link_preview_url: if(is_deleted, do: nil, else: m.link_preview_url),
        link_preview_title: if(is_deleted, do: nil, else: m.link_preview_title),
        link_preview_description: if(is_deleted, do: nil, else: m.link_preview_description),
        link_preview_image_url: if(is_deleted, do: nil, else: m.link_preview_image_url),
        reactions: reactions
      }
    end)
  end

  @doc false
  # Fetches `message`'s first URL's Open Graph tags (falling back to
  # <title>) and attaches them as a link preview. Best-effort and
  # asynchronous — never blocks sending the message, and a failure
  # just means no preview shows.
  defp maybe_fetch_link_preview(%Message{text: text, id: message_id}) do
    case Regex.run(@url_pattern, text) do
      [url] ->
        Task.start(fn -> fetch_and_attach_link_preview(message_id, url) end)
        :ok

      _ ->
        :ok
    end
  end

  defp fetch_and_attach_link_preview(message_id, url) do
    with {:ok, 200, _headers, body} <- :hackney.request(:get, url, [], "", [:with_body, follow_redirect: true, max_redirect: 3, recv_timeout: 6_000]),
         html <- to_string(body),
         title <- extract_meta(html, "og:title") || extract_title_tag(html),
         description <- extract_meta(html, "og:description") || extract_meta(html, "description"),
         image <- extract_meta(html, "og:image"),
         true <- title != nil or description != nil or image != nil,
         %Message{deleted_at: nil} = message <- Repo.get(Message, message_id) do
      message
      |> Ecto.Changeset.change(
        link_preview_url: url,
        link_preview_title: title,
        link_preview_description: description,
        link_preview_image_url: image
      )
      |> Repo.update()
      |> case do
        {:ok, updated} -> broadcast_update(to_view(updated))
        _ -> :ok
      end
    else
      _ -> :ok
    end
  rescue
    _ -> :ok
  end

  defp extract_meta(html, property) do
    forward =
      ~r/<meta[^>]+(?:property|name)=["']#{Regex.escape(property)}["'][^>]+content=["']([^"']*)["']/i

    reversed =
      ~r/<meta[^>]+content=["']([^"']*)["'][^>]+(?:property|name)=["']#{Regex.escape(property)}["']/i

    case Regex.run(forward, html) || Regex.run(reversed, html) do
      [_, content] -> unescape_html(content)
      _ -> nil
    end
  end

  defp extract_title_tag(html) do
    case Regex.run(~r/<title[^>]*>([^<]*)<\/title>/i, html) do
      [_, title] -> unescape_html(title)
      _ -> nil
    end
  end

  defp unescape_html(nil), do: nil

  defp unescape_html(s) do
    s
    |> String.replace("&amp;", "&")
    |> String.replace("&quot;", "\"")
    |> String.replace("&#39;", "'")
    |> String.replace("&lt;", "<")
    |> String.replace("&gt;", ">")
    |> String.trim()
  end
end
