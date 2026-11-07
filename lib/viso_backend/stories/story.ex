defmodule VisoBackend.Stories.Story do
  use Ecto.Schema

  schema "stories" do
    field :media_url, :string
    field :media_type, :string
    field :view_count, :integer, default: 0
    field :expires_at, :utc_datetime

    belongs_to :author, VisoBackend.Accounts.User

    timestamps(type: :utc_datetime)
  end
end
