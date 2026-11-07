defmodule VisoBackend.Posts do
  @moduledoc """
  Real post creation, a ranked feed, likes and view counts. Mirrors
  the old vibe_server's PostEndpoint.
  """

  import Ecto.Query
  alias VisoBackend.Repo
  alias VisoBackend.Posts.{Post, PostLike}

  @doc "Creates a post for `author_id`."
  def create_post(author_id, attrs) do
    %Post{}
    |> Post.changeset(Map.put(attrs, "author_id", author_id))
    |> Repo.insert()
  end

  @doc """
  Returns a ranked page of recent posts, annotated with whether
  `viewer_id` has liked each one. Ranking is a simple, explainable
  "hot" score: engagement (likes + weighted comments) decayed by how
  long ago the post was made, so fresh posts with traction rise to
  the top without older popular posts dominating forever.
  """
  def list_feed(viewer_id, limit, offset) do
    # Pull a recent window to rank in memory; fine at current scale and
    # keeps the ranking formula simple to read/tune.
    posts =
      from(p in Post, order_by: [desc: p.inserted_at], limit: 300)
      |> Repo.all()
      |> Repo.preload(:author)

    now = DateTime.utc_now()

    ranked =
      Enum.sort_by(posts, &score(&1, now), :desc)
      |> Enum.slice(offset, limit)

    annotate_liked(ranked, viewer_id)
  end

  @doc "Returns `author_id`'s own posts, most recent first."
  def list_my_posts(author_id) do
    posts =
      from(p in Post,
        where: p.author_id == ^author_id,
        order_by: [desc: p.inserted_at],
        limit: 100
      )
      |> Repo.all()
      |> Repo.preload(:author)

    annotate_liked(posts, author_id)
  end

  defp annotate_liked([], _viewer_id), do: []

  defp annotate_liked(posts, viewer_id) do
    post_ids = Enum.map(posts, & &1.id)

    liked_ids =
      from(l in PostLike, where: l.user_id == ^viewer_id and l.post_id in ^post_ids, select: l.post_id)
      |> Repo.all()
      |> MapSet.new()

    Enum.map(posts, fn post -> {post, MapSet.member?(liked_ids, post.id)} end)
  end

  defp score(%Post{} = post, now) do
    hours_old = DateTime.diff(now, post.inserted_at, :second) / 3600.0
    engagement = post.like_count + post.comment_count * 1.5
    engagement / :math.pow(hours_old + 2, 1.5)
  end

  @doc """
  Toggles whether `user_id` likes `post_id`. Returns `{:ok, new_like_count}`
  or `{:error, :not_found}`.
  """
  def toggle_like(user_id, post_id) do
    Repo.transaction(fn ->
      case Repo.get(Post, post_id) do
        nil ->
          Repo.rollback(:not_found)

        post ->
          existing = Repo.get_by(PostLike, post_id: post_id, user_id: user_id)

          new_count =
            if existing do
              Repo.delete!(existing)
              max(post.like_count - 1, 0)
            else
              Repo.insert!(%PostLike{post_id: post_id, user_id: user_id})
              post.like_count + 1
            end

          post
          |> Ecto.Changeset.change(like_count: new_count)
          |> Repo.update!()

          new_count
      end
    end)
  end

  @doc """
  Increments the view count for `post_id`. Best-effort: the client
  calls this once per post per session, so counts are approximate,
  not a unique-viewer count.
  """
  def record_view(post_id) do
    from(p in Post, where: p.id == ^post_id)
    |> Repo.update_all(inc: [view_count: 1])

    :ok
  end
end
