defmodule VisoBackend.Chat do
  @moduledoc """
  1:1 messaging. `conversation_topic/2` is the piece that ties this
  context to the real-time layer: both participants in a chat join the
  exact same Phoenix Channel topic, derived deterministically from
  their two user ids, so broadcasting to that topic reaches both of
  them automatically — no separate "conversation" record needed yet.
  """

  import Ecto.Query
  alias VisoBackend.Repo
  alias VisoBackend.Chat.Message

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

  def send_message(sender_id, recipient_id, text) do
    %Message{}
    |> Message.changeset(%{sender_id: sender_id, recipient_id: recipient_id, text: text})
    |> Repo.insert()
  end

  @doc "Message history between two users, oldest first."
  def list_messages(user_id, partner_id, limit \\ 50) do
    from(m in Message,
      where:
        (m.sender_id == ^user_id and m.recipient_id == ^partner_id) or
          (m.sender_id == ^partner_id and m.recipient_id == ^user_id),
      order_by: [asc: m.inserted_at],
      limit: ^limit
    )
    |> Repo.all()
  end
end
