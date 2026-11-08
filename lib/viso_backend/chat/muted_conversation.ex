defmodule VisoBackend.Chat.MutedConversation do
  use Ecto.Schema

  schema "muted_conversations" do
    belongs_to :user, VisoBackend.Accounts.User
    belongs_to :muted_user, VisoBackend.Accounts.User

    timestamps(type: :utc_datetime)
  end
end
