defmodule VisoBackendWeb.UsersJSON do
  alias VisoBackend.Accounts.User

  @doc "Renders a list of users — e.g. search results."
  def index(%{users: users}) do
    %{users: Enum.map(users, &data/1)}
  end

  @doc "Renders a single user's public profile."
  def show(%{user: user}) do
    %{user: data(user)}
  end

  # Deliberately omits email — this is another user's public profile,
  # unlike AuthJSON's data/1 which is only ever the signed-in user's own.
  defp data(%User{} = user) do
    %{
      id: user.id,
      full_name: user.full_name,
      username: user.username,
      image_url: user.image_url,
      bio: user.bio
    }
  end
end
