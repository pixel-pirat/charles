defmodule VisoBackend.Repo.Migrations.CreatePosts do
  use Ecto.Migration

  def change do
    create table(:posts) do
      add :author_id, references(:users, on_delete: :delete_all), null: false
      add :text, :text, null: false, default: ""
      add :media_urls, {:array, :string}, null: false, default: []
      add :media_type, :string, null: false, default: "none"
      add :like_count, :integer, null: false, default: 0
      add :comment_count, :integer, null: false, default: 0
      add :view_count, :integer, null: false, default: 0

      timestamps(type: :utc_datetime)
    end

    create index(:posts, [:author_id])
    create index(:posts, [:inserted_at])

    create table(:post_likes) do
      add :post_id, references(:posts, on_delete: :delete_all), null: false
      add :user_id, references(:users, on_delete: :delete_all), null: false

      timestamps(type: :utc_datetime)
    end

    create unique_index(:post_likes, [:post_id, :user_id])
  end
end
