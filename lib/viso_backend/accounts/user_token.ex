defmodule VisoBackend.Accounts.UserToken do
  use Ecto.Schema
  import Ecto.Query

  @rand_size 32

  schema "users_tokens" do
    field :token, :binary
    field :context, :string
    belongs_to :user, VisoBackend.Accounts.User

    timestamps(type: :utc_datetime, updated_at: false)
  end

  @doc """
  Builds a fresh API token for `user`. Returns both the raw bytes (to
  hand back to the client) and the struct to insert — the raw token is
  nothing but cryptographically random bytes, not derived from
  anything about the user, so looking it up later by exact match is
  safe.
  """
  def build_api_token(user) do
    token = :crypto.strong_rand_bytes(@rand_size)
    {token, %__MODULE__{token: token, context: "api-auth", user_id: user.id}}
  end

  @doc "Query matching the user a given raw token belongs to, if any."
  def verify_api_token_query(token) do
    query =
      from t in __MODULE__,
        where: t.token == ^token and t.context == "api-auth",
        join: u in assoc(t, :user),
        select: u

    {:ok, query}
  end
end
