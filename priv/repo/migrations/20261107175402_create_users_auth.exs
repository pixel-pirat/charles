defmodule VisoBackend.Repo.Migrations.CreateUsersAuth do
  use Ecto.Migration

  def change do
    create table(:users) do
      add :email, :string, null: false
      add :hashed_password, :string, null: false
      add :full_name, :string
      add :username, :string

      timestamps(type: :utc_datetime)
    end

    create unique_index(:users, [:email])
    create unique_index(:users, [:username])

    # API bearer tokens. `context` distinguishes token purposes (just
    # "api-auth" for now; room to add "password-reset" etc. later
    # without a schema change).
    create table(:users_tokens) do
      add :user_id, references(:users, on_delete: :delete_all), null: false
      add :token, :binary, null: false
      add :context, :string, null: false

      timestamps(type: :utc_datetime, updated_at: false)
    end

    create unique_index(:users_tokens, [:token])
    create index(:users_tokens, [:user_id])
  end
end
