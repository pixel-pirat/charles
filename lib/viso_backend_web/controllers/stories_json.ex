defmodule VisoBackendWeb.StoriesJSON do
  alias VisoBackend.Accounts

  @doc "Renders the grouped stories feed."
  def index(%{groups: groups}) do
    %{groups: Enum.map(groups, &group_data/1)}
  end

  defp group_data(%{author: author, has_unseen: has_unseen, stories: stories}) do
    %{
      author_id: author.id,
      author_name: Accounts.display_name(author),
      author_avatar_url: author.image_url,
      has_unseen: has_unseen,
      stories: Enum.map(stories, &story_data/1)
    }
  end

  defp story_data(%{story: story, is_seen_by_me: is_seen_by_me}) do
    %{
      id: story.id,
      media_url: story.media_url,
      media_type: story.media_type,
      created_at: story.inserted_at,
      view_count: story.view_count,
      is_seen_by_me: is_seen_by_me
    }
  end
end
