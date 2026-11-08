defmodule VisoBackend.Chat.PinnedConversation do
  use Ecto.Schema

  schema "pinned_conversations" do
    belongs_to :user, VisoBackend.Accounts.User
    belongs_to :pinned_user, VisoBackend.Accounts.User

    timestamps(type: :utc_datetime)
  end
end
