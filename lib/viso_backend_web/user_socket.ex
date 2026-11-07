defmodule VisoBackendWeb.UserSocket do
  use Phoenix.Socket

  # Any topic starting with "room:" is handled by RoomChannel — the
  # specific room id (e.g. "room:2-5") is parsed inside its join/3.
  channel "room:*", VisoBackendWeb.RoomChannel

  @impl true
  def connect(%{"token" => token}, socket, _connect_info) do
    case VisoBackend.Accounts.fetch_user_by_api_token(token) do
      {:ok, user} -> {:ok, assign(socket, :current_user, user)}
      :error -> {:error, :unauthorized}
    end
  end

  def connect(_params, _socket, _connect_info), do: {:error, :unauthorized}

  # Used to identify/disconnect this socket later (e.g. force-logout
  # all of a user's connections). Must be unique per connected user.
  @impl true
  def id(socket), do: "user_socket:#{socket.assigns.current_user.id}"
end
