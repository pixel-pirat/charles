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

  # Chat.send_message/3 broadcasts "new_message" to the room itself
  # (shared by this channel path and the REST fallback at
  # POST /api/chat/messages), so this handler doesn't broadcast again
  # — it just persists and replies with the outcome.
  @impl true
  def handle_in("new_message", %{"text" => text, "recipient_id" => recipient_id} = params, socket) do
    sender_id = socket.assigns.current_user.id

    attrs = %{
      "text" => text,
      "media_url" => params["media_url"],
      "media_type" => params["media_type"],
      "reply_to_message_id" => params["reply_to_message_id"]
    }

    case Chat.send_message(sender_id, recipient_id, attrs) do
      {:ok, _view} ->
        {:reply, :ok, socket}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:reply, {:error, %{errors: changeset_errors(changeset)}}, socket}

      {:error, reason} ->
        {:reply, {:error, %{reason: to_string(reason)}}, socket}
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
