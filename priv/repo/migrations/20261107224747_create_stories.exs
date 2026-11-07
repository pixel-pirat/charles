defmodule VisoBackend.Repo.Migrations.CreateStories do
  use Ecto.Migration

  def change do
    create table(:stories) do
      add :author_id, references(:users, on_delete: :delete_all), null: false
      add :media_url, :string, null: false
      add :media_type, :string, null: false
      add :view_count, :integer, null: false, default: 0
      add :expires_at, :utc_datetime, null: false

      timestamps(type: :utc_datetime)
    end

    create index(:stories, [:author_id])
    create index(:stories, [:expires_at])

    create table(:story_views) do
      add :story_id, references(:stories, on_delete: :delete_all), null: false
      add :viewer_id, references(:users, on_delete: :delete_all), null: false

      timestamps(type: :utc_datetime)
    end

    create unique_index(:story_views, [:story_id, :viewer_id])
  end
end
