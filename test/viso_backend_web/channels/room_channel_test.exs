defmodule VisoBackendWeb.RoomChannelTest do
  # async: false + :shared sandbox mode because RoomChannel spawns its
  # own process per join, and that process needs to use the *same*
  # sandboxed DB connection/transaction as this test — by default each
  # process gets its own, which would make the channel unable to see
  # (or safely touch) data this test set up.
  use VisoBackendWeb.ChannelCase, async: false

  alias VisoBackend.{Accounts, Chat}
  alias VisoBackendWeb.{Presence, RoomChannel, UserSocket}

  setup do
    Ecto.Adapters.SQL.Sandbox.mode(VisoBackend.Repo, {:shared, self()})

    {:ok, user_a} = Accounts.register_user(%{email: "a@example.com", password: "password123"})
    {:ok, user_b} = Accounts.register_user(%{email: "b@example.com", password: "password123"})
    {:ok, user_c} = Accounts.register_user(%{email: "c@example.com", password: "password123"})

    %{
      user_a: user_a,
      user_b: user_b,
      user_c: user_c,
      token_a: Accounts.create_api_token(user_a),
      token_b: Accounts.create_api_token(user_b),
      token_c: Accounts.create_api_token(user_c)
    }
  end

  test "both participants are tracked in presence once joined", %{
    user_a: user_a,
    user_b: user_b,
    token_a: token_a,
    token_b: token_b
  } do
    {:ok, socket_a} = connect(UserSocket, %{"token" => token_a})
    {:ok, socket_b} = connect(UserSocket, %{"token" => token_b})
    room = Chat.conversation_topic(user_a.id, user_b.id)

    {:ok, _reply, _socket_a} = subscribe_and_join(socket_a, RoomChannel, room)
    {:ok, _reply, _socket_b} = subscribe_and_join(socket_b, RoomChannel, room)

    presences = Presence.list(room)
    assert Map.has_key?(presences, to_string(user_a.id))
    assert Map.has_key?(presences, to_string(user_b.id))
  end

  test "sending a message broadcasts it to the room and persists it", %{
    user_a: user_a,
    user_b: user_b,
    token_a: token_a,
    token_b: token_b
  } do
    {:ok, socket_a} = connect(UserSocket, %{"token" => token_a})
    {:ok, socket_b} = connect(UserSocket, %{"token" => token_b})
    room = Chat.conversation_topic(user_a.id, user_b.id)

    {:ok, _reply, socket_a} = subscribe_and_join(socket_a, RoomChannel, room)
    {:ok, _reply, _socket_b} = subscribe_and_join(socket_b, RoomChannel, room)

    ref = push(socket_a, "new_message", %{"text" => "hello", "recipient_id" => user_b.id})
    assert_reply ref, :ok
    assert_broadcast "new_message", %{text: "hello", sender_id: sender_id}
    assert sender_id == user_a.id
    assert [%Chat.Message{text: "hello"}] = Chat.list_messages(user_a.id, user_b.id)
  end

  test "a user cannot join a room that isn't theirs", %{
    token_c: token_c,
    user_a: user_a,
    user_b: user_b
  } do
    {:ok, socket_c} = connect(UserSocket, %{"token" => token_c})
    room = Chat.conversation_topic(user_a.id, user_b.id)

    assert {:error, %{reason: "unauthorized"}} = subscribe_and_join(socket_c, RoomChannel, room)
  end

  test "connect/3 rejects an invalid token" do
    assert {:error, :unauthorized} = connect(UserSocket, %{"token" => "garbage"})
  end
end
