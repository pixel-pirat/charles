defmodule VisoBackend.Chat.Message do
  use Ecto.Schema
  import Ecto.Changeset

  schema "messages" do
    field :text, :string, default: ""
    field :media_url, :string
    field :media_type, :string
    field :read_at, :utc_datetime
    field :delivered_at, :utc_datetime
    field :edited_at, :utc_datetime
    field :deleted_at, :utc_datetime
    field :hidden_for_sender, :utc_datetime
    field :hidden_for_recipient, :utc_datetime
    field :link_preview_url, :string
    field :link_preview_title, :string
    field :link_preview_description, :string
    field :link_preview_image_url, :string

    belongs_to :sender, VisoBackend.Accounts.User
    belongs_to :recipient, VisoBackend.Accounts.User
    belongs_to :reply_to_message, __MODULE__

    timestamps(type: :utc_datetime, updated_at: false)
  end

  @doc """
  A message needs text or an attachment (or both, e.g. a captioned
  photo) — mirrors the old vibe_server's ChatEndpoint.sendMessage.
  """
  def changeset(message, attrs) do
    message
    |> cast(attrs, [
      :text,
      :sender_id,
      :recipient_id,
      :media_url,
      :media_type,
      :reply_to_message_id
    ])
    |> validate_required([:sender_id, :recipient_id])
    |> update_change(:text, &String.trim/1)
    |> validate_length(:text, max: 4000)
    |> validate_text_or_media()
  end

  defp validate_text_or_media(changeset) do
    text = get_field(changeset, :text) || ""
    media_url = get_field(changeset, :media_url)

    if text == "" and is_nil(media_url) do
      add_error(changeset, :text, "a message needs text or an attachment")
    else
      changeset
    end
  end
end
