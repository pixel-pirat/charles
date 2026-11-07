defmodule VisoBackendWeb.AuthJSON do
  alias VisoBackend.Accounts.User

  @doc "Renders a user plus a fresh API token, right after register/login."
  def auth(%{user: user, token: token}) do
    %{user: data(user), token: token}
  end

  @doc "Renders just a user — e.g. for GET /api/me."
  def show(%{user: user}) do
    %{user: data(user)}
  end

  defp data(%User{} = user) do
    %{
      id: user.id,
      email: user.email,
      full_name: user.full_name,
      username: user.username
    }
  end
end
