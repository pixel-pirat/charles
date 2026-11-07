defmodule VisoBackendWeb.StoriesControllerTest do
  use VisoBackendWeb.ConnCase, async: true

  alias VisoBackend.Accounts

  setup do
    {:ok, user_a} =
      Accounts.register_user(%{email: "story_a@example.com", password: "password123"})

    {:ok, user_b} =
      Accounts.register_user(%{email: "story_b@example.com", password: "password123"})

    %{
      user_a: user_a,
      user_b: user_b,
      token_a: Accounts.create_api_token(user_a),
      token_b: Accounts.create_api_token(user_b)
    }
  end

  defp authed(conn, token), do: put_req_header(conn, "authorization", "Bearer #{token}")

  test "POST /api/stories creates a story", %{conn: conn, token_a: token_a} do
    conn =
      conn
      |> authed(token_a)
      |> post(~p"/api/stories", %{"media_url" => "https://example.com/a.jpg", "media_type" => "image"})

    assert %{"id" => _id} = json_response(conn, 201)
  end

  test "feed groups stories by author and marks my own group's unseen state", %{
    conn: conn,
    token_a: token_a,
    token_b: token_b,
    user_a: user_a,
    user_b: user_b
  } do
    conn
    |> authed(token_a)
    |> post(~p"/api/stories", %{"media_url" => "https://example.com/a.jpg", "media_type" => "image"})

    %{"id" => story_b_id} =
      conn
      |> authed(token_b)
      |> post(~p"/api/stories", %{"media_url" => "https://example.com/b.jpg", "media_type" => "image"})
      |> json_response(201)

    feed = conn |> authed(token_a) |> get(~p"/api/stories") |> json_response(200)
    assert length(feed["groups"]) == 2

    # My own group always comes first.
    [own_group | _] = feed["groups"]
    assert own_group["author_id"] == user_a.id

    other_group = Enum.find(feed["groups"], &(&1["author_id"] == user_b.id))
    assert other_group["has_unseen"] == true
    [story] = other_group["stories"]
    assert story["id"] == story_b_id
    assert story["is_seen_by_me"] == false
  end

  test "marking a story viewed updates seen state and view count exactly once", %{
    conn: conn,
    token_a: token_a,
    token_b: token_b,
    user_b: user_b
  } do
    %{"id" => story_id} =
      conn
      |> authed(token_b)
      |> post(~p"/api/stories", %{"media_url" => "https://example.com/b.jpg", "media_type" => "image"})
      |> json_response(201)

    conn_a = authed(conn, token_a)
    conn_a |> post(~p"/api/stories/#{story_id}/view") |> response(204)
    conn_a |> post(~p"/api/stories/#{story_id}/view") |> response(204)

    feed = conn_a |> get(~p"/api/stories") |> json_response(200)
    other_group = Enum.find(feed["groups"], &(&1["author_id"] == user_b.id))

    assert other_group["has_unseen"] == false
    [story] = other_group["stories"]
    assert story["is_seen_by_me"] == true
    assert story["view_count"] == 1
  end
end
