defmodule ExChat.Web.RouterTest do
  use ExUnit.Case, async: true
  import WebSocketClient

  alias ExChat.Supervisor

  setup do
    start_supervised Supervisor
    %{}
  end

  describe "when join the default chat room" do
    setup do
      {:ok, ws_client} = connect_to "ws://localhost:4000/room", forward_to: self()
      send_as_text(ws_client, "{\"command\":\"join\"}")

      {:ok, ws_client: ws_client}
    end

    test "a welcome message is received" do
      assert_receive "{\"room\":\"default\",\"message\":\"welcome to the default chat room!\"}"
    end

    test "each message sent is received back", %{ws_client: ws_client} do
      send_as_text(ws_client, "{\"room\":\"default\",\"message\":\"Hello folks!\"}")

      assert_receive "{\"room\":\"default\",\"message\":\"Hello folks!\"}"
    end

    test "we receive all the messages sent by other clients" do
      {:ok, other_client} = connect_to "ws://localhost:4000/room", forward_to: NullProcess.start
      send_as_text(other_client, "{\"command\":\"join\"}")

      send_as_text(other_client, "{\"room\":\"default\",\"message\":\"Hello from Twitch!\"}")

      assert_receive "{\"room\":\"default\",\"message\":\"Hello from Twitch!\"}"
    end
  end

  describe "when join a new chat room" do
    setup do
      {:ok, ws_client} = connect_to "ws://localhost:4000/room", forward_to: self()
      send_as_text(ws_client, "{\"command\":\"join\",\"room\":\"a_chat_room\"}")

      {:ok, ws_client: ws_client}
    end

    test "a welcome message is received" do
      assert_receive "{\"room\":\"a_chat_room\",\"message\":\"welcome to the a_chat_room chat room!\"}"
    end

    test "each message sent is received back", %{ws_client: ws_client} do
      send_as_text(ws_client, "{\"room\":\"a_chat_room\",\"message\":\"Hello folks!\"}")

      assert_receive "{\"room\":\"a_chat_room\",\"message\":\"Hello folks!\"}"
    end
  end
end