defmodule VisoBackendWeb.LobbyChannel do
  @moduledoc """
  A single shared topic every connected client joins on app start,
  independent of which (if any) conversation they're viewing — this
  is what lets the chat list show accurate "online" badges for every
  partner, not just whoever's room you currently have open. The old
  vibe_server tracked this via a client heartbeat polling an endpoint
  every 30s; Phoenix.Presence does it for free, in real time, with no
  polling.
  """
  use VisoBackendWeb, :channel

  alias VisoBackendWeb.Presence

  @impl true
  def join("lobby", _params, socket) do
    send(self(), :after_join)
    {:ok, socket}
  end

  @impl true
  def handle_info(:after_join, socket) do
    {:ok, _} =
      Presence.track(socket, to_string(socket.assigns.current_user.id), %{
        online_at: System.system_time(:second)
      })

    push(socket, "presence_state", Presence.list(socket))
    {:noreply, socket}
  end
end
