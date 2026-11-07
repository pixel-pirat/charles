defmodule VisoBackend.Stories.StoryView do
  use Ecto.Schema

  schema "story_views" do
    belongs_to :story, VisoBackend.Stories.Story
    belongs_to :viewer, VisoBackend.Accounts.User

    timestamps(type: :utc_datetime)
  end
end
