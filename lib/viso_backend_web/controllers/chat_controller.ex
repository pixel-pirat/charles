defmodule VisoBackendWeb.ChatController do
  use VisoBackendWeb, :controller

  alias VisoBackend.Chat

  @doc "GET /api/chat/conversations"
  def conversations(conn, _params) do
    json(conn, %{conversations: Chat.list_conversations(conn.assigns.current_user.id)})
  end

  @doc "GET /api/chat/conversations/archived"
  def archived_conversations(conn, _params) do
    json(conn, %{conversations: Chat.get_archived_conversations(conn.assigns.current_user.id)})
  end

  @doc "GET /api/chat/messages/:partner_id"
  def messages(conn, %{"partner_id" => partner_id}) do
    with {parsed_id, ""} <- Integer.parse(partner_id) do
      json(conn, %{messages: Chat.list_messages(conn.assigns.current_user.id, parsed_id)})
    else
      _ -> conn |> put_status(:bad_request) |> json(%{error: "invalid partner_id"})
    end
  end

  @doc """
  POST /api/chat/messages — REST fallback for sending (the Channel
  path at RoomChannel is the primary one; both call the same context
  function, so either way the message broadcasts live to the room).
  """
  def send_message(conn, %{"recipient_id" => recipient_id} = params) do
    attrs = Map.take(params, ["text", "media_url", "media_type", "reply_to_message_id"])

    case Chat.send_message(conn.assigns.current_user.id, recipient_id, attrs) do
      {:ok, view} ->
        conn |> put_status(:created) |> json(%{message: view})

      {:error, %Ecto.Changeset{} = changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> put_view(json: VisoBackendWeb.ChangesetJSON)
        |> render(:error, changeset: changeset)

      {:error, reason} ->
        conn |> put_status(:unprocessable_entity) |> json(%{error: to_string(reason)})
    end
  end

  @doc "POST /api/chat/messages/:id/forward"
  def forward(conn, %{"id" => id, "recipient_id" => recipient_id}) do
    with {message_id, ""} <- Integer.parse(id),
         {:ok, view} <- Chat.forward_message(conn.assigns.current_user.id, message_id, recipient_id) do
      conn |> put_status(:created) |> json(%{message: view})
    else
      _ -> conn |> put_status(:not_found) |> json(%{error: "message not found"})
    end
  end

  @doc "PATCH /api/chat/messages/:id — edits the signed-in user's own message."
  def edit(conn, %{"id" => id, "text" => text}) do
    with {message_id, ""} <- Integer.parse(id),
         {:ok, view} <- Chat.edit_message(conn.assigns.current_user.id, message_id, text) do
      json(conn, %{message: view})
    else
      _ -> conn |> put_status(:not_found) |> json(%{error: "message not found"})
    end
  end

  @doc "DELETE /api/chat/messages/:id — deletes for everyone (sender only)."
  def delete(conn, %{"id" => id}) do
    with {message_id, ""} <- Integer.parse(id),
         {:ok, view} <- Chat.delete_message_for_everyone(conn.assigns.current_user.id, message_id) do
      json(conn, %{message: view})
    else
      _ -> conn |> put_status(:not_found) |> json(%{error: "message not found"})
    end
  end

  @doc "POST /api/chat/messages/:id/delete_for_me"
  def delete_for_me(conn, %{"id" => id}) do
    case Integer.parse(id) do
      {message_id, ""} -> Chat.delete_message_for_me(conn.assigns.current_user.id, message_id)
      _ -> :ok
    end

    send_resp(conn, :no_content, "")
  end

  @doc "POST /api/chat/messages/:id/react — body: {\"emoji\": \"...\"}"
  def react(conn, %{"id" => id, "emoji" => emoji}) do
    with {message_id, ""} <- Integer.parse(id),
         {:ok, view} <- Chat.react_to_message(conn.assigns.current_user.id, message_id, emoji) do
      json(conn, %{message: view})
    else
      _ -> conn |> put_status(:not_found) |> json(%{error: "message not found"})
    end
  end

  @doc "POST /api/chat/conversations/:partner_id/read"
  def mark_read(conn, %{"partner_id" => partner_id}) do
    with {id, ""} <- Integer.parse(partner_id) do
      Chat.mark_conversation_read(conn.assigns.current_user.id, id)
      send_resp(conn, :no_content, "")
    else
      _ -> conn |> put_status(:bad_request) |> json(%{error: "invalid partner_id"})
    end
  end

  @doc "POST /api/chat/blocks/:user_id"
  def block(conn, %{"user_id" => user_id}) do
    with {id, ""} <- Integer.parse(user_id),
         {:ok, _} <- Chat.block_user(conn.assigns.current_user.id, id) do
      send_resp(conn, :no_content, "")
    else
      {:error, :cannot_block_self} ->
        conn |> put_status(:unprocessable_entity) |> json(%{error: "cannot block yourself"})

      _ ->
        conn |> put_status(:bad_request) |> json(%{error: "invalid user_id"})
    end
  end

  @doc "DELETE /api/chat/blocks/:user_id"
  def unblock(conn, %{"user_id" => user_id}) do
    case Integer.parse(user_id) do
      {id, ""} -> Chat.unblock_user(conn.assigns.current_user.id, id)
      _ -> :ok
    end

    send_resp(conn, :no_content, "")
  end

  @doc "GET /api/chat/blocks"
  def blocked_users(conn, _params) do
    users =
      Chat.get_blocked_users(conn.assigns.current_user.id)
      |> Enum.map(fn u ->
        %{id: u.id, full_name: u.full_name, username: u.username, image_url: u.image_url}
      end)

    json(conn, %{users: users})
  end

  @doc "POST /api/chat/mutes/:partner_id"
  def mute(conn, %{"partner_id" => partner_id}), do: toggle(conn, partner_id, &Chat.mute_conversation/2)

  @doc "DELETE /api/chat/mutes/:partner_id"
  def unmute(conn, %{"partner_id" => partner_id}), do: toggle(conn, partner_id, &Chat.unmute_conversation/2)

  @doc "POST /api/chat/pins/:partner_id"
  def pin(conn, %{"partner_id" => partner_id}), do: toggle(conn, partner_id, &Chat.pin_conversation/2)

  @doc "DELETE /api/chat/pins/:partner_id"
  def unpin(conn, %{"partner_id" => partner_id}), do: toggle(conn, partner_id, &Chat.unpin_conversation/2)

  @doc "POST /api/chat/archives/:partner_id"
  def archive(conn, %{"partner_id" => partner_id}), do: toggle(conn, partner_id, &Chat.archive_conversation/2)

  @doc "DELETE /api/chat/archives/:partner_id"
  def unarchive(conn, %{"partner_id" => partner_id}), do: toggle(conn, partner_id, &Chat.unarchive_conversation/2)

  defp toggle(conn, partner_id, fun) do
    case Integer.parse(partner_id) do
      {id, ""} -> fun.(conn.assigns.current_user.id, id)
      _ -> :ok
    end

    send_resp(conn, :no_content, "")
  end

  @doc "POST /api/chat/stars/:message_id"
  def star(conn, %{"message_id" => message_id}) do
    case Integer.parse(message_id) do
      {id, ""} -> Chat.star_message(conn.assigns.current_user.id, id)
      _ -> :ok
    end

    send_resp(conn, :no_content, "")
  end

  @doc "DELETE /api/chat/stars/:message_id"
  def unstar(conn, %{"message_id" => message_id}) do
    case Integer.parse(message_id) do
      {id, ""} -> Chat.unstar_message(conn.assigns.current_user.id, id)
      _ -> :ok
    end

    send_resp(conn, :no_content, "")
  end

  @doc "GET /api/chat/stars"
  def starred_messages(conn, _params) do
    json(conn, %{messages: Chat.get_starred_messages(conn.assigns.current_user.id)})
  end
end
