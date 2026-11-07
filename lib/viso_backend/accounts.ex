defmodule VisoBackend.Accounts do
  @moduledoc """
  The public boundary for everything user/auth related. Controllers
  (and later, Channels) call into this module rather than touching
  `VisoBackend.Accounts.User`/`UserToken` or `Repo` directly — this is
  the "context" pattern Phoenix apps use to keep business logic out of
  the web layer.
  """

  import Ecto.Query
  alias VisoBackend.Repo
  alias VisoBackend.Accounts.{User, UserToken}

  @doc "Registers a new account. Returns {:ok, user} or {:error, changeset}."
  def register_user(attrs) do
    %User{}
    |> User.registration_changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Returns the user if `email`/`password` match, otherwise `nil`. Always
  runs a password verification (even for a nonexistent email, against a
  dummy hash) so a timing attack can't be used to discover which emails
  are registered.
  """
  def get_user_by_email_and_password(email, password)
      when is_binary(email) and is_binary(password) do
    user = Repo.get_by(User, email: String.downcase(email))

    if user && Pbkdf2.verify_pass(password, user.hashed_password) do
      user
    else
      Pbkdf2.no_user_verify()
      nil
    end
  end

  def get_user!(id), do: Repo.get!(User, id)

  @doc "Sets a display name and @handle on an existing account."
  def update_profile(user, attrs) do
    user
    |> User.profile_changeset(attrs)
    |> Repo.update()
  end

  @doc "Issues a new API bearer token for `user`, as a URL-safe string."
  def create_api_token(user) do
    {raw_token, user_token} = UserToken.build_api_token(user)
    Repo.insert!(user_token)
    Base.url_encode64(raw_token, padding: false)
  end

  @doc "Resolves a bearer token string back to its user, if valid."
  def fetch_user_by_api_token(encoded_token) when is_binary(encoded_token) do
    with {:ok, token} <- Base.url_decode64(encoded_token, padding: false),
         {:ok, query} <- UserToken.verify_api_token_query(token),
         %User{} = user <- Repo.one(query) do
      {:ok, user}
    else
      _ -> :error
    end
  end

  def fetch_user_by_api_token(_), do: :error

  @doc "Revokes a bearer token (logout)."
  def revoke_api_token(encoded_token) when is_binary(encoded_token) do
    case Base.url_decode64(encoded_token, padding: false) do
      {:ok, token} -> Repo.delete_all(from t in UserToken, where: t.token == ^token)
      :error -> :ok
    end

    :ok
  end

  def revoke_api_token(_), do: :ok
end
