defmodule VisoBackendWeb.RoomChannel do
  use VisoBackendWeb, :channel

  alias VisoBackend.Chat
  alias VisoBackendWeb.Presence

  @impl true
  def join("room:" <> room_id, _params, socket) do
    user_id = socket.assigns.current_user.id

    if Chat.topic_includes_user?(room_id, user_id) do
      send(self(), :after_join)
      {:ok, assign(socket, :room_id, room_id)}
    else
      {:error, %{reason: "unauthorized"}}
    end
  end

  # Runs just after join/3 replies — tracking presence inside join/3
  # itself isn't allowed because the socket isn't fully registered in
  # the channel registry yet at that point.
  @impl true
  def handle_info(:after_join, socket) do
    {:ok, _} =
      Presence.track(socket, to_string(socket.assigns.current_user.id), %{
        online_at: System.system_time(:second)
      })

    push(socket, "presence_state", Presence.list(socket))
    {:noreply, socket}
  end

  @impl true
  def handle_in("new_message", %{"text" => text, "recipient_id" => recipient_id}, socket) do
    sender_id = socket.assigns.current_user.id

    case Chat.send_message(sender_id, recipient_id, text) do
      {:ok, message} ->
        broadcast!(socket, "new_message", %{
          id: message.id,
          sender_id: message.sender_id,
          recipient_id: message.recipient_id,
          text: message.text,
          inserted_at: message.inserted_at
        })

        {:reply, :ok, socket}

      {:error, changeset} ->
        {:reply, {:error, %{errors: changeset_errors(changeset)}}, socket}
    end
  end

  @impl true
  def handle_in("typing", %{"is_typing" => is_typing}, socket) do
    broadcast_from!(socket, "typing", %{
      user_id: socket.assigns.current_user.id,
      is_typing: is_typing
    })

    {:noreply, socket}
  end

  defp changeset_errors(changeset) do
    Ecto.Changeset.traverse_errors(changeset, fn {msg, _opts} -> msg end)
  end
end
