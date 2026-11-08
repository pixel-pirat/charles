defmodule VisoBackend.Chat.ArchivedConversation do
  use Ecto.Schema

  schema "archived_conversations" do
    belongs_to :user, VisoBackend.Accounts.User
    belongs_to :archived_user, VisoBackend.Accounts.User

    timestamps(type: :utc_datetime)
  end
end
