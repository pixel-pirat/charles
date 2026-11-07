defmodule VisoBackendWeb.UsersControllerTest do
  use VisoBackendWeb.ConnCase, async: true

  alias VisoBackend.Accounts

  setup do
    {:ok, user_a} =
      Accounts.register_user(%{email: "profile_a@example.com", password: "password123"})

    {:ok, user_b} =
      Accounts.register_user(%{email: "profile_b@example.com", password: "password123"})

    {:ok, user_b} =
      Accounts.update_profile(user_b, %{full_name: "Barbara Lee", username: "barbara"})

    %{user_a: user_a, user_b: user_b, token_a: Accounts.create_api_token(user_a)}
  end

  defp authed(conn, token) do
    put_req_header(conn, "authorization", "Bearer #{token}")
  end

  test "PATCH /api/me updates profile fields", %{conn: conn, token_a: token_a} do
    conn =
      conn
      |> authed(token_a)
      |> patch(~p"/api/me", %{
        "full_name" => "Alice Doe",
        "username" => "alice_d",
        "bio" => "hello world",
        "image_url" => "https://example.com/a.jpg"
      })

    assert %{
             "user" => %{
               "full_name" => "Alice Doe",
               "username" => "alice_d",
               "bio" => "hello world",
               "image_url" => "https://example.com/a.jpg"
             }
           } = json_response(conn, 200)
  end

  test "PATCH /api/me rejects a taken username", %{
    conn: conn,
    token_a: token_a,
    user_b: user_b
  } do
    conn =
      conn
      |> authed(token_a)
      |> patch(~p"/api/me", %{"username" => user_b.username})

    assert %{"errors" => %{"username" => [_ | _]}} = json_response(conn, 422)
  end

  test "GET /api/users/search finds users by username or full name", %{
    conn: conn,
    token_a: token_a,
    user_b: user_b
  } do
    conn = conn |> authed(token_a) |> get(~p"/api/users/search?q=barb")
    assert %{"users" => [found]} = json_response(conn, 200)
    assert found["id"] == user_b.id
    refute Map.has_key?(found, "email")
  end

  test "GET /api/users/search excludes the signed-in user and short queries", %{
    conn: conn,
    token_a: token_a
  } do
    conn = conn |> authed(token_a) |> get(~p"/api/users/search?q=a")
    assert %{"users" => []} = json_response(conn, 200)
  end

  test "GET /api/users/:id returns another user's public profile", %{
    conn: conn,
    token_a: token_a,
    user_b: user_b
  } do
    conn = conn |> authed(token_a) |> get(~p"/api/users/#{user_b.id}")
    assert %{"user" => %{"id" => id, "username" => "barbara"}} = json_response(conn, 200)
    assert id == user_b.id
  end

  test "GET /api/users/:id 404s for a nonexistent id", %{conn: conn, token_a: token_a} do
    conn = conn |> authed(token_a) |> get(~p"/api/users/999999999")
    assert json_response(conn, 404)
  end
end
