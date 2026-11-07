defmodule VisoBackendWeb.HealthController do
  use VisoBackendWeb, :controller

  def show(conn, _params) do
    send_resp(conn, :ok, "ok")
  end
end
