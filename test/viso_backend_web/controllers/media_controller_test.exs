defmodule VisoBackendWeb.MediaControllerTest do
  use VisoBackendWeb.ConnCase, async: true

  alias VisoBackend.Accounts

  setup do
    {:ok, user} = Accounts.register_user(%{email: "media@example.com", password: "password123"})
    %{token: Accounts.create_api_token(user)}
  end

  defp authed(conn, token) do
    put_req_header(conn, "authorization", "Bearer #{token}")
  end

  # Hits the real Cloudflare R2 bucket (same approach as the Neon-backed
  # tests elsewhere in this suite) — genuinely verifies the upload
  # round-trips to a fetchable public URL, not just that the code runs.
  test "POST /api/media uploads a file and returns a fetchable public URL", %{
    conn: conn,
    token: token
  } do
    path = Path.join(System.tmp_dir!(), "media_controller_test_#{System.unique_integer()}.txt")
    File.write!(path, "hello from a controller test")

    on_exit(fn -> File.rm(path) end)

    upload = %Plug.Upload{path: path, filename: "note.txt", content_type: "text/plain"}

    conn = conn |> authed(token) |> post(~p"/api/media", %{"file" => upload})
    assert %{"url" => url} = json_response(conn, 201)

    assert {:ok, 200, _headers, body} =
             :hackney.request(:get, url, [], "", [:with_body])

    assert body == "hello from a controller test"
  end

  test "POST /api/media without a file is a 422", %{conn: conn, token: token} do
    conn = conn |> authed(token) |> post(~p"/api/media", %{})
    assert json_response(conn, 422)
  end
end
