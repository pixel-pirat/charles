defmodule VisoBackendWeb.PostsController do
  use VisoBackendWeb, :controller

  alias VisoBackend.Posts

  @doc "POST /api/posts — creates a post."
  def create(conn, params) do
    case Posts.create_post(conn.assigns.current_user.id, params) do
      {:ok, post} ->
        post = VisoBackend.Repo.preload(post, :author)

        conn
        |> put_status(:created)
        |> render(:show, post: post, is_liked_by_me: false)

      {:error, changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> put_view(json: VisoBackendWeb.ChangesetJSON)
        |> render(:error, changeset: changeset)
    end
  end

  @doc "GET /api/posts/feed?limit=&offset= — the ranked home feed."
  def feed(conn, params) do
    limit = params |> Map.get("limit", "20") |> parse_int(20)
    offset = params |> Map.get("offset", "0") |> parse_int(0)

    posts = Posts.list_feed(conn.assigns.current_user.id, limit, offset)
    render(conn, :index, posts: posts)
  end

  @doc "GET /api/posts/mine — the signed-in user's own posts."
  def mine(conn, _params) do
    posts = Posts.list_my_posts(conn.assigns.current_user.id)
    render(conn, :index, posts: posts)
  end

  @doc "POST /api/posts/:id/like — toggles the signed-in user's like."
  def like(conn, %{"id" => id}) do
    with {post_id, ""} <- Integer.parse(id),
         {:ok, like_count} <- Posts.toggle_like(conn.assigns.current_user.id, post_id) do
      json(conn, %{like_count: like_count})
    else
      _ -> conn |> put_status(:not_found) |> json(%{error: "post not found"})
    end
  end

  @doc "POST /api/posts/:id/view — records a view (best-effort)."
  def view(conn, %{"id" => id}) do
    case Integer.parse(id) do
      {post_id, ""} -> Posts.record_view(post_id)
      _ -> :ok
    end

    send_resp(conn, :no_content, "")
  end

  defp parse_int(value, _default) when is_integer(value), do: value

  defp parse_int(value, default) when is_binary(value) do
    case Integer.parse(value) do
      {int, ""} -> int
      _ -> default
    end
  end
end
