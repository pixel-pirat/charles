defmodule VisoBackendWeb.StoriesController do
  use VisoBackendWeb, :controller

  alias VisoBackend.Stories

  @doc "POST /api/stories — creates a story (expires in 24h)."
  def create(conn, %{"media_url" => media_url, "media_type" => media_type}) do
    case Stories.create_story(conn.assigns.current_user.id, media_url, media_type) do
      {:ok, story} ->
        conn |> put_status(:created) |> json(%{id: story.id})

      {:error, changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> put_view(json: VisoBackendWeb.ChangesetJSON)
        |> render(:error, changeset: changeset)
    end
  end

  @doc "GET /api/stories — active stories grouped by author."
  def feed(conn, _params) do
    groups = Stories.get_stories_feed(conn.assigns.current_user.id)
    render(conn, :index, groups: groups)
  end

  @doc "POST /api/stories/:id/view — marks a story as viewed (idempotent)."
  def mark_viewed(conn, %{"id" => id}) do
    case Integer.parse(id) do
      {story_id, ""} -> Stories.mark_story_viewed(conn.assigns.current_user.id, story_id)
      _ -> :ok
    end

    send_resp(conn, :no_content, "")
  end
end
