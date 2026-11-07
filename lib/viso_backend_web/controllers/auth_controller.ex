defmodule VisoBackendWeb.AuthController do
  use VisoBackendWeb, :controller

  alias VisoBackend.Accounts
  alias VisoBackend.Accounts.User

  @doc "POST /api/register — creates an account and returns a bearer token."
  def register(conn, params) do
    case Accounts.register_user(params) do
      {:ok, user} ->
        token = Accounts.create_api_token(user)

        conn
        |> put_status(:created)
        |> render(:auth, user: user, token: token)

      {:error, changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> put_view(json: VisoBackendWeb.ChangesetJSON)
        |> render(:error, changeset: changeset)
    end
  end

  @doc "POST /api/login — verifies credentials and returns a bearer token."
  def login(conn, %{"email" => email, "password" => password}) do
    case Accounts.get_user_by_email_and_password(email, password) do
      %User{} = user ->
        token = Accounts.create_api_token(user)
        render(conn, :auth, user: user, token: token)

      nil ->
        conn
        |> put_status(:unauthorized)
        |> json(%{error: "invalid email or password"})
    end
  end

  @doc "DELETE /api/logout — revokes the bearer token used for this request."
  def logout(conn, _params) do
    ["Bearer " <> token] = get_req_header(conn, "authorization")
    Accounts.revoke_api_token(token)
    send_resp(conn, :no_content, "")
  end

  @doc "GET /api/me — returns the signed-in user."
  def me(conn, _params) do
    render(conn, :show, user: conn.assigns.current_user)
  end
end
