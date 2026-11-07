defmodule VisoBackendWeb.PostsControllerTest do
  use VisoBackendWeb.ConnCase, async: true

  alias VisoBackend.Accounts

  setup do
    {:ok, user_a} = Accounts.register_user(%{email: "post_a@example.com", password: "password123"})
    {:ok, user_b} = Accounts.register_user(%{email: "post_b@example.com", password: "password123"})

    %{
      user_a: user_a,
      user_b: user_b,
      token_a: Accounts.create_api_token(user_a),
      token_b: Accounts.create_api_token(user_b)
    }
  end

  defp authed(conn, token), do: put_req_header(conn, "authorization", "Bearer #{token}")

  test "POST /api/posts creates a post", %{conn: conn, token_a: token_a} do
    conn = conn |> authed(token_a) |> post(~p"/api/posts", %{"text" => "hello feed"})

    assert %{
             "post" => %{
               "text" => "hello feed",
               "like_count" => 0,
               "is_liked_by_me" => false
             }
           } = json_response(conn, 201)
  end

  test "POST /api/posts rejects an empty post", %{conn: conn, token_a: token_a} do
    conn = conn |> authed(token_a) |> post(~p"/api/posts", %{"text" => ""})
    assert json_response(conn, 422)
  end

  test "feed shows posts from other users and reflects my like state", %{
    conn: conn,
    token_a: token_a,
    token_b: token_b
  } do
    conn
    |> authed(token_a)
    |> post(~p"/api/posts", %{"text" => "from a"})

    %{"post" => %{"id" => post_id}} =
      conn
      |> authed(token_b)
      |> post(~p"/api/posts", %{"text" => "from b"})
      |> json_response(201)

    conn |> authed(token_a) |> post(~p"/api/posts/#{post_id}/like")

    feed = conn |> authed(token_a) |> get(~p"/api/posts/feed") |> json_response(200)
    liked_post = Enum.find(feed["posts"], &(&1["id"] == post_id))

    assert liked_post["is_liked_by_me"] == true
    assert liked_post["like_count"] == 1
    assert liked_post["author_name"] != nil
    assert length(feed["posts"]) == 2
  end

  test "GET /api/posts/mine only returns my own posts", %{
    conn: conn,
    token_a: token_a,
    token_b: token_b
  } do
    conn |> authed(token_a) |> post(~p"/api/posts", %{"text" => "mine"})
    conn |> authed(token_b) |> post(~p"/api/posts", %{"text" => "not mine"})

    mine = conn |> authed(token_a) |> get(~p"/api/posts/mine") |> json_response(200)
    assert [%{"text" => "mine"}] = mine["posts"]
  end

  test "liking twice toggles back off", %{conn: conn, token_a: token_a} do
    %{"post" => %{"id" => post_id}} =
      conn |> authed(token_a) |> post(~p"/api/posts", %{"text" => "toggle me"}) |> json_response(201)

    conn = conn |> authed(token_a)
    assert %{"like_count" => 1} = conn |> post(~p"/api/posts/#{post_id}/like") |> json_response(200)
    assert %{"like_count" => 0} = conn |> post(~p"/api/posts/#{post_id}/like") |> json_response(200)
  end

  test "view count increments and is reflected in the feed", %{conn: conn, token_a: token_a} do
    %{"post" => %{"id" => post_id}} =
      conn |> authed(token_a) |> post(~p"/api/posts", %{"text" => "viewed"}) |> json_response(201)

    conn = conn |> authed(token_a)
    conn |> post(~p"/api/posts/#{post_id}/view") |> response(204)
    conn |> post(~p"/api/posts/#{post_id}/view") |> response(204)

    mine = conn |> get(~p"/api/posts/mine") |> json_response(200)
    assert [%{"view_count" => 2}] = mine["posts"]
  end
end
