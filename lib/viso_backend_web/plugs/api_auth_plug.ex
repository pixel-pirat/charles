defmodule VisoBackendWeb.ApiAuthPlug do
  @moduledoc """
  Reads the `Authorization: Bearer <token>` header, resolves it to a
  user via `VisoBackend.Accounts`, and assigns it as `current_user`.
  Returns 401 and halts the pipeline if the token is missing or
  invalid — put this in a pipeline in front of any route that requires
  a signed-in user.
  """
  import Plug.Conn
  alias VisoBackend.Accounts

  def init(opts), do: opts

  def call(conn, _opts) do
    with ["Bearer " <> token] <- get_req_header(conn, "authorization"),
         {:ok, user} <- Accounts.fetch_user_by_api_token(token) do
      assign(conn, :current_user, user)
    else
      _ ->
        conn
        |> put_status(:unauthorized)
        |> Phoenix.Controller.json(%{error: "unauthenticated"})
        |> halt()
    end
  end
end
