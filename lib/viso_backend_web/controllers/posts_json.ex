defmodule VisoBackendWeb.PostsJSON do
  alias VisoBackend.Accounts
  alias VisoBackend.Posts.Post

  @doc "Renders a feed/my-posts page: a list of {post, is_liked_by_me} tuples."
  def index(%{posts: posts}) do
    %{posts: Enum.map(posts, fn {post, is_liked} -> data(post, is_liked) end)}
  end

  @doc "Renders a single freshly created post."
  def show(%{post: post, is_liked_by_me: is_liked_by_me}) do
    %{post: data(post, is_liked_by_me)}
  end

  defp data(%Post{} = post, is_liked_by_me) do
    author = post.author

    %{
      id: post.id,
      author_id: post.author_id,
      author_name: Accounts.display_name(author),
      author_username: author.username,
      author_avatar_url: author.image_url,
      text: post.text,
      media_urls: post.media_urls,
      media_type: post.media_type,
      created_at: post.inserted_at,
      like_count: post.like_count,
      comment_count: post.comment_count,
      view_count: post.view_count,
      is_liked_by_me: is_liked_by_me
    }
  end
end
