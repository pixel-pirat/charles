defmodule VisoBackend.Chat.BlockedUser do
  use Ecto.Schema

  schema "blocked_users" do
    belongs_to :blocker, VisoBackend.Accounts.User
    belongs_to :blocked, VisoBackend.Accounts.User

    timestamps(type: :utc_datetime)
  end
end
