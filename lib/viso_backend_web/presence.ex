defmodule VisoBackendWeb.Presence do
  @moduledoc """
  Tracks who's currently online in a given Channel topic. This is one
  of the two concrete Phoenix features (the other being Channels
  themselves) that were the actual reason for choosing this stack —
  distributed presence tracking that works across multiple server
  nodes with no extra infrastructure (no Redis needed).
  """
  use Phoenix.Presence,
    otp_app: :viso_backend,
    pubsub_server: VisoBackend.PubSub
end
