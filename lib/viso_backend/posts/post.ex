defmodule VisoBackend.Posts.Post do
  use Ecto.Schema
  import Ecto.Changeset

  schema "posts" do
    field :text, :string, default: ""
    field :media_urls, {:array, :string}, default: []
    field :media_type, :string, default: "none"
    field :like_count, :integer, default: 0
    field :comment_count, :integer, default: 0
    field :view_count, :integer, default: 0

    belongs_to :author, VisoBackend.Accounts.User

    timestamps(type: :utc_datetime)
  end

  @doc """
  A post needs text or at least one media URL (or both, e.g. a
  captioned photo) — mirrors the old vibe_server's PostEndpoint.
  """
  def changeset(post, attrs) do
    post
    |> cast(attrs, [:author_id, :text, :media_urls, :media_type])
    |> validate_required([:author_id])
    |> update_change(:text, &String.trim/1)
    |> validate_media_type()
    |> validate_text_or_media()
  end

  defp validate_media_type(changeset) do
    validate_inclusion(changeset, :media_type, ["none", "image", "video"])
  end

  defp validate_text_or_media(changeset) do
    text = get_field(changeset, :text) || ""
    media_urls = get_field(changeset, :media_urls) || []

    if text == "" and media_urls == [] do
      add_error(changeset, :text, "a post needs text or at least one photo/video")
    else
      changeset
    end
  end
end
