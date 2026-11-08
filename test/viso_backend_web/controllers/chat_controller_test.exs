defmodule VisoBackendWeb.ChatControllerTest do
  use VisoBackendWeb.ConnCase, async: true

  alias VisoBackend.Accounts

  setup do
    {:ok, user_a} = Accounts.register_user(%{email: "chat_a@example.com", password: "password123"})
    {:ok, user_b} = Accounts.register_user(%{email: "chat_b@example.com", password: "password123"})
    {:ok, user_c} = Accounts.register_user(%{email: "chat_c@example.com", password: "password123"})

    %{
      user_a: user_a,
      user_b: user_b,
      user_c: user_c,
      token_a: Accounts.create_api_token(user_a),
      token_b: Accounts.create_api_token(user_b),
      token_c: Accounts.create_api_token(user_c)
    }
  end

  defp authed(conn, token), do: put_req_header(conn, "authorization", "Bearer #{token}")

  defp send_msg(conn, token, recipient_id, text) do
    conn
    |> authed(token)
    |> post(~p"/api/chat/messages", %{"recipient_id" => recipient_id, "text" => text})
    |> json_response(201)
    |> Map.fetch!("message")
  end

  test "POST /api/chat/messages sends and GET /api/chat/messages/:partner_id lists it", %{
    conn: conn,
    token_a: token_a,
    user_a: user_a,
    user_b: user_b
  } do
    message = send_msg(conn, token_a, user_b.id, "hello b")
    assert message["text"] == "hello b"
    assert message["sender_id"] == user_a.id
    assert message["is_deleted"] == false

    history =
      conn
      |> authed(token_a)
      |> get(~p"/api/chat/messages/#{user_b.id}")
      |> json_response(200)

    assert [%{"text" => "hello b"}] = history["messages"]
  end

  test "sending to a blocked user is rejected", %{
    conn: conn,
    token_a: token_a,
    token_b: token_b,
    user_a: user_a,
    user_b: user_b
  } do
    conn |> authed(token_a) |> post(~p"/api/chat/blocks/#{user_b.id}") |> response(204)

    conn =
      conn
      |> authed(token_b)
      |> post(~p"/api/chat/messages", %{"recipient_id" => user_a.id, "text" => "hi"})

    assert json_response(conn, 422)
  end

  test "unblocking allows messaging again", %{
    conn: conn,
    token_a: token_a,
    user_b: user_b
  } do
    conn |> authed(token_a) |> post(~p"/api/chat/blocks/#{user_b.id}") |> response(204)
    conn |> authed(token_a) |> delete(~p"/api/chat/blocks/#{user_b.id}") |> response(204)

    message = send_msg(conn, token_a, user_b.id, "we're good now")
    assert message["text"] == "we're good now"
  end

  test "GET /api/chat/blocks lists blocked users", %{
    conn: conn,
    token_a: token_a,
    user_b: user_b
  } do
    conn |> authed(token_a) |> post(~p"/api/chat/blocks/#{user_b.id}") |> response(204)
    blocked = conn |> authed(token_a) |> get(~p"/api/chat/blocks") |> json_response(200)
    assert [%{"id" => id}] = blocked["users"]
    assert id == user_b.id
  end

  test "editing a message sets edited_at and updates text", %{
    conn: conn,
    token_a: token_a,
    user_b: user_b
  } do
    message = send_msg(conn, token_a, user_b.id, "oops")

    edited =
      conn
      |> authed(token_a)
      |> patch(~p"/api/chat/messages/#{message["id"]}", %{"text" => "fixed"})
      |> json_response(200)
      |> Map.fetch!("message")

    assert edited["text"] == "fixed"
    assert edited["edited_at"] != nil
  end

  test "another user cannot edit someone else's message", %{
    conn: conn,
    token_a: token_a,
    token_b: token_b,
    user_b: user_b
  } do
    message = send_msg(conn, token_a, user_b.id, "mine")

    conn =
      conn
      |> authed(token_b)
      |> patch(~p"/api/chat/messages/#{message["id"]}", %{"text" => "hijacked"})

    assert json_response(conn, 404)
  end

  test "deleting for everyone clears content for both participants", %{
    conn: conn,
    token_a: token_a,
    token_b: token_b,
    user_a: user_a,
    user_b: user_b
  } do
    message = send_msg(conn, token_a, user_b.id, "secret")

    conn |> authed(token_a) |> delete(~p"/api/chat/messages/#{message["id"]}") |> json_response(200)

    history =
      conn
      |> authed(token_b)
      |> get(~p"/api/chat/messages/#{user_a.id}")
      |> json_response(200)

    assert [%{"text" => "", "is_deleted" => true}] = history["messages"]
  end

  test "deleting for me only hides it from my own view", %{
    conn: conn,
    token_a: token_a,
    token_b: token_b,
    user_a: user_a,
    user_b: user_b
  } do
    message = send_msg(conn, token_a, user_b.id, "hide from me")

    conn
    |> authed(token_a)
    |> post(~p"/api/chat/messages/#{message["id"]}/delete_for_me")
    |> response(204)

    mine = conn |> authed(token_a) |> get(~p"/api/chat/messages/#{user_b.id}") |> json_response(200)
    assert mine["messages"] == []

    theirs = conn |> authed(token_b) |> get(~p"/api/chat/messages/#{user_a.id}") |> json_response(200)
    assert [%{"text" => "hide from me"}] = theirs["messages"]
  end

  test "reacting then reacting with the same emoji toggles it off", %{
    conn: conn,
    token_a: token_a,
    token_b: token_b,
    user_b: user_b
  } do
    message = send_msg(conn, token_a, user_b.id, "react to me")
    conn_b = authed(conn, token_b)

    reacted =
      conn_b
      |> post(~p"/api/chat/messages/#{message["id"]}/react", %{"emoji" => "👍"})
      |> json_response(200)
      |> Map.fetch!("message")

    assert [%{"emoji" => "👍"}] = reacted["reactions"]

    unreacted =
      conn_b
      |> post(~p"/api/chat/messages/#{message["id"]}/react", %{"emoji" => "👍"})
      |> json_response(200)
      |> Map.fetch!("message")

    assert unreacted["reactions"] == []
  end

  test "forwarding re-sends the content to a new recipient", %{
    conn: conn,
    token_a: token_a,
    user_b: user_b,
    user_c: user_c
  } do
    message = send_msg(conn, token_a, user_b.id, "forward me")

    forwarded =
      conn
      |> authed(token_a)
      |> post(~p"/api/chat/messages/#{message["id"]}/forward", %{"recipient_id" => user_c.id})
      |> json_response(201)
      |> Map.fetch!("message")

    assert forwarded["text"] == "forward me"
    assert forwarded["recipient_id"] == user_c.id
  end

  test "conversations list shows unread count and marking read clears it", %{
    conn: conn,
    token_a: token_a,
    token_b: token_b,
    user_a: user_a,
    user_b: user_b
  } do
    send_msg(conn, token_b, user_a.id, "unread 1")
    send_msg(conn, token_b, user_a.id, "unread 2")

    convos = conn |> authed(token_a) |> get(~p"/api/chat/conversations") |> json_response(200)
    [convo] = convos["conversations"]
    assert convo["partner_id"] == user_b.id
    assert convo["unread_count"] == 2

    conn |> authed(token_a) |> post(~p"/api/chat/conversations/#{user_b.id}/read") |> response(204)

    convos = conn |> authed(token_a) |> get(~p"/api/chat/conversations") |> json_response(200)
    [convo] = convos["conversations"]
    assert convo["unread_count"] == 0
  end

  test "pinning moves a conversation to the top and archiving removes it from the main list", %{
    conn: conn,
    token_a: token_a,
    user_b: user_b,
    user_c: user_c
  } do
    send_msg(conn, token_a, user_b.id, "to b")
    send_msg(conn, token_a, user_c.id, "to c")

    conn |> authed(token_a) |> post(~p"/api/chat/pins/#{user_c.id}") |> response(204)

    convos = conn |> authed(token_a) |> get(~p"/api/chat/conversations") |> json_response(200)
    assert [%{"partner_id" => partner_id, "is_pinned" => true} | _] = convos["conversations"]
    assert partner_id == user_c.id

    conn |> authed(token_a) |> post(~p"/api/chat/archives/#{user_c.id}") |> response(204)

    active = conn |> authed(token_a) |> get(~p"/api/chat/conversations") |> json_response(200)
    assert Enum.all?(active["conversations"], &(&1["partner_id"] != user_c.id))

    archived =
      conn |> authed(token_a) |> get(~p"/api/chat/conversations/archived") |> json_response(200)

    assert [%{"partner_id" => archived_partner_id}] = archived["conversations"]
    assert archived_partner_id == user_c.id
  end

  test "starring a message adds it to the starred list", %{
    conn: conn,
    token_a: token_a,
    user_b: user_b
  } do
    message = send_msg(conn, token_a, user_b.id, "star me")

    conn |> authed(token_a) |> post(~p"/api/chat/stars/#{message["id"]}") |> response(204)

    starred = conn |> authed(token_a) |> get(~p"/api/chat/stars") |> json_response(200)
    assert [%{"text" => "star me"}] = starred["messages"]

    conn |> authed(token_a) |> delete(~p"/api/chat/stars/#{message["id"]}") |> response(204)
    starred = conn |> authed(token_a) |> get(~p"/api/chat/stars") |> json_response(200)
    assert starred["messages"] == []
  end
end
