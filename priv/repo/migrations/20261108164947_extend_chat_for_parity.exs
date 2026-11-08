defmodule VisoBackend.Repo.Migrations.ExtendChatForParity do
  use Ecto.Migration

  def change do
    alter table(:messages) do
      modify :text, :string, null: false, default: ""
      add :media_url, :string
      add :media_type, :string
      add :reply_to_message_id, references(:messages, on_delete: :nilify_all)
      add :delivered_at, :utc_datetime
      add :edited_at, :utc_datetime
      add :deleted_at, :utc_datetime
      add :hidden_for_sender, :utc_datetime
      add :hidden_for_recipient, :utc_datetime
      add :link_preview_url, :string
      add :link_preview_title, :string
      add :link_preview_description, :string
      add :link_preview_image_url, :string
    end

    create index(:messages, [:reply_to_message_id])

    create table(:message_reactions) do
      add :message_id, references(:messages, on_delete: :delete_all), null: false
      add :user_id, references(:users, on_delete: :delete_all), null: false
      add :emoji, :string, null: false

      timestamps(type: :utc_datetime)
    end

    create unique_index(:message_reactions, [:message_id, :user_id])

    create table(:blocked_users) do
      add :blocker_id, references(:users, on_delete: :delete_all), null: false
      add :blocked_id, references(:users, on_delete: :delete_all), null: false

      timestamps(type: :utc_datetime)
    end

    create unique_index(:blocked_users, [:blocker_id, :blocked_id])

    create table(:muted_conversations) do
      add :user_id, references(:users, on_delete: :delete_all), null: false
      add :muted_user_id, references(:users, on_delete: :delete_all), null: false

      timestamps(type: :utc_datetime)
    end

    create unique_index(:muted_conversations, [:user_id, :muted_user_id])

    create table(:pinned_conversations) do
      add :user_id, references(:users, on_delete: :delete_all), null: false
      add :pinned_user_id, references(:users, on_delete: :delete_all), null: false

      timestamps(type: :utc_datetime)
    end

    create unique_index(:pinned_conversations, [:user_id, :pinned_user_id])

    create table(:archived_conversations) do
      add :user_id, references(:users, on_delete: :delete_all), null: false
      add :archived_user_id, references(:users, on_delete: :delete_all), null: false

      timestamps(type: :utc_datetime)
    end

    create unique_index(:archived_conversations, [:user_id, :archived_user_id])

    create table(:starred_messages) do
      add :user_id, references(:users, on_delete: :delete_all), null: false
      add :message_id, references(:messages, on_delete: :delete_all), null: false

      timestamps(type: :utc_datetime)
    end

    create unique_index(:starred_messages, [:user_id, :message_id])
  end
end
