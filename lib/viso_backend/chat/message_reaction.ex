defmodule VisoBackend.Chat.MessageReaction do
  use Ecto.Schema

  schema "message_reactions" do
    field :emoji, :string
    belongs_to :message, VisoBackend.Chat.Message
    belongs_to :user, VisoBackend.Accounts.User

    timestamps(type: :utc_datetime)
  end
end
