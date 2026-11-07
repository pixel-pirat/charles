defmodule VisoBackend.Repo.Migrations.CreateMessages do
  use Ecto.Migration

  def change do
    create table(:messages) do
      add :sender_id, references(:users, on_delete: :delete_all), null: false
      add :recipient_id, references(:users, on_delete: :delete_all), null: false
      add :text, :string, null: false
      add :read_at, :utc_datetime

      timestamps(type: :utc_datetime, updated_at: false)
    end

    create index(:messages, [:sender_id, :recipient_id, :inserted_at])
    create index(:messages, [:recipient_id, :sender_id, :inserted_at])
  end
end
