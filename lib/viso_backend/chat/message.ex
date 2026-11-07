defmodule VisoBackend.Chat.Message do
  use Ecto.Schema
  import Ecto.Changeset

  schema "messages" do
    field :text, :string
    field :read_at, :utc_datetime
    belongs_to :sender, VisoBackend.Accounts.User
    belongs_to :recipient, VisoBackend.Accounts.User

    timestamps(type: :utc_datetime, updated_at: false)
  end

  def changeset(message, attrs) do
    message
    |> cast(attrs, [:text, :sender_id, :recipient_id])
    |> validate_required([:text, :sender_id, :recipient_id])
    |> validate_length(:text, min: 1, max: 4000)
  end
end
