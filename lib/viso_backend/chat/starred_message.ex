defmodule VisoBackend.Chat.StarredMessage do
  use Ecto.Schema

  schema "starred_messages" do
    belongs_to :user, VisoBackend.Accounts.User
    belongs_to :message, VisoBackend.Chat.Message

    timestamps(type: :utc_datetime)
  end
end
