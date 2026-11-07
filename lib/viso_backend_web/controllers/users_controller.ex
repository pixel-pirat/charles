defmodule VisoBackendWeb.UsersController do
  use VisoBackendWeb, :controller

  alias VisoBackend.Accounts

  @doc "GET /api/users/search?q=... — up to 20 matches, excluding yourself."
  def search(conn, params) do
    query = Map.get(params, "q", "")
    users = Accounts.search_users(query, conn.assigns.current_user.id)
    render(conn, :index, users: users)
  end

  @doc "GET /api/users/:id — another user's public profile."
  def show(conn, %{"id" => id}) do
    with {parsed_id, ""} <- Integer.parse(id),
         %Accounts.User{} = user <- Accounts.get_user(parsed_id) do
      render(conn, :show, user: user)
    else
      _ ->
        conn
        |> put_status(:not_found)
        |> json(%{error: "user not found"})
    end
  end
end
