defmodule VisoBackend.Accounts.User do
  use Ecto.Schema
  import Ecto.Changeset

  schema "users" do
    field :email, :string
    # `redact: true` keeps these out of logs/inspect output if a
    # changeset or struct ever gets logged by accident.
    field :hashed_password, :string, redact: true
    # `virtual: true` means this field exists on the struct but has no
    # column in the database — it only carries the plaintext password
    # from the request through the changeset pipeline long enough to
    # hash it below. It's never persisted.
    field :password, :string, virtual: true, redact: true
    field :full_name, :string
    field :username, :string
    field :image_url, :string
    field :bio, :string

    timestamps(type: :utc_datetime)
  end

  @doc """
  Changeset for registering a new account: validates/normalizes the
  email, requires a password of at least 8 characters, and replaces it
  with its hashed form before the struct ever reaches the database.
  """
  def registration_changeset(user, attrs) do
    user
    |> cast(attrs, [:email, :password])
    |> validate_email()
    |> validate_password()
  end

  defp validate_email(changeset) do
    changeset
    |> validate_required([:email])
    |> validate_format(:email, ~r/^[^\s]+@[^\s]+\.[^\s]+$/, message: "must be a valid email")
    |> validate_length(:email, max: 160)
    |> update_change(:email, &String.downcase/1)
    |> unsafe_validate_unique(:email, VisoBackend.Repo)
    |> unique_constraint(:email)
  end

  defp validate_password(changeset) do
    changeset
    |> validate_required([:password])
    |> validate_length(:password, min: 8, max: 72)
    |> maybe_hash_password()
  end

  defp maybe_hash_password(changeset) do
    password = get_change(changeset, :password)

    if password && changeset.valid? do
      changeset
      |> put_change(:hashed_password, Pbkdf2.hash_pwd_salt(password))
      |> delete_change(:password)
    else
      changeset
    end
  end

  @doc """
  Changeset for setting/editing profile fields: display name, handle,
  avatar, bio. `full_name`/`username` are required overall (so the
  very first call, completing signup, must set them), but a later call
  can send just e.g. `image_url` without re-sending the rest — the
  existing stored values already satisfy `validate_required`.
  """
  def profile_changeset(user, attrs) do
    user
    |> cast(attrs, [:full_name, :username, :image_url, :bio])
    |> validate_required([:full_name, :username])
    |> validate_length(:username, min: 3, max: 30)
    |> validate_format(:username, ~r/^[a-zA-Z0-9_]+$/,
      message: "can only contain letters, numbers and underscores"
    )
    |> validate_length(:bio, max: 280)
    |> unsafe_validate_unique(:username, VisoBackend.Repo)
    |> unique_constraint(:username)
  end
end
