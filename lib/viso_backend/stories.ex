defmodule VisoBackend.Stories do
  @moduledoc """
  Stories: 24h-expiring photo/video updates, grouped by author, with
  seen/view tracking. Mirrors the old vibe_server's StoryEndpoint.
  """

  import Ecto.Query
  alias VisoBackend.Repo
  alias VisoBackend.Stories.{Story, StoryView}

  @doc "Creates a story. Expires 24 hours from now."
  def create_story(author_id, media_url, media_type) do
    now = DateTime.utc_now() |> DateTime.truncate(:second)

    %Story{}
    |> Ecto.Changeset.change(%{
      author_id: author_id,
      media_url: media_url,
      media_type: media_type,
      expires_at: DateTime.add(now, 24 * 3600, :second)
    })
    |> Repo.insert()
  end

  @doc """
  Returns active (non-expired) stories grouped by author, as
  `%{author: %User{}, has_unseen: bool, stories: [%{story:, is_seen_by_me:}]}`.
  The signed-in user's own group (if any) always comes first; the
  rest are ordered unseen-first, then by most recent story.
  """
  def get_stories_feed(viewer_id) do
    now = DateTime.utc_now()

    stories =
      from(s in Story, where: s.expires_at > ^now, order_by: [asc: s.inserted_at])
      |> Repo.all()
      |> Repo.preload(:author)

    if stories == [] do
      []
    else
      story_ids = Enum.map(stories, & &1.id)

      seen_ids =
        from(v in StoryView, where: v.viewer_id == ^viewer_id and v.story_id in ^story_ids, select: v.story_id)
        |> Repo.all()
        |> MapSet.new()

      stories
      |> Enum.group_by(& &1.author_id)
      |> Enum.map(fn {_author_id, author_stories} ->
        author = hd(author_stories).author
        has_unseen = Enum.any?(author_stories, &(not MapSet.member?(seen_ids, &1.id)))

        %{
          author: author,
          has_unseen: has_unseen,
          stories:
            Enum.map(author_stories, fn s ->
              %{story: s, is_seen_by_me: MapSet.member?(seen_ids, s.id)}
            end)
        }
      end)
      |> Enum.sort(fn a, b -> compare_groups(a, b, viewer_id) end)
    end
  end

  defp compare_groups(%{author: %{id: id}}, _b, viewer_id) when id == viewer_id, do: true
  defp compare_groups(_a, %{author: %{id: id}}, viewer_id) when id == viewer_id, do: false

  defp compare_groups(a, b, _viewer_id) do
    cond do
      a.has_unseen != b.has_unseen -> a.has_unseen
      true -> latest_story_time(a) |> DateTime.compare(latest_story_time(b)) != :lt
    end
  end

  defp latest_story_time(group) do
    group.stories |> List.last() |> Map.fetch!(:story) |> Map.fetch!(:inserted_at)
  end

  @doc """
  Marks `story_id` as viewed by `viewer_id` (idempotent) and bumps its
  view count the first time.
  """
  def mark_story_viewed(viewer_id, story_id) do
    case Repo.get_by(StoryView, story_id: story_id, viewer_id: viewer_id) do
      nil ->
        Repo.insert!(%StoryView{story_id: story_id, viewer_id: viewer_id})

        from(s in Story, where: s.id == ^story_id)
        |> Repo.update_all(inc: [view_count: 1])

        :ok

      _already_viewed ->
        :ok
    end
  end
end
