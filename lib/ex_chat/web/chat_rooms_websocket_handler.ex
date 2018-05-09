defmodule ExChat.Web.ChatRoomsWebSocketHandler do

  @behaviour :cowboy_websocket_handler

  def init(_, _req, _opts) do
    {:upgrade, :protocol, :cowboy_websocket}
  end

  def websocket_init(_type, req, _opts) do
    state = nil
    {:ok, req, state}
  end

  def websocket_handle({:text, command_as_json}, req, state) do
    handle(from_json(command_as_json), req, state)
  end

  def websocket_handle(_message, req, state) do
    {:ok, req, state}
  end

  def websocket_info({chatroom_name, message}, req, state) do
    response = %{
      room: chatroom_name,
      message: message
    }

    {:reply, {:text, to_json(response)}, req, state}
  end

  def websocket_terminate(_reason, _req, _state) do
    :ok
  end

  defp handle(%{"command" => "join", "room" => room}, req, state) do
    response = case ExChat.ChatRooms.join(room, self()) do
      :ok ->
        %{ room: room, message: "welcome to the " <> room <> " chat room!" }
      {:error, :unexisting_room} ->
        %{ error: room <> " does not exists" }
    end

    {:reply, {:text, to_json(response)}, req, state}
  end

  defp handle(command = %{"command" => "join"}, req, state) do
    handle(Map.put(command, "room", "default"), req, state)
  end

  defp handle(%{"room" => room, "message" => message}, req, state) do
    :ok = ExChat.ChatRooms.send(room, message)

    {:ok, req, state}
  end

  defp handle(%{"command" => "create", "room" => room}, req, state) do
    response = case ExChat.ChatRooms.create(room) do
      :ok -> %{success: room <> " has been created!"}
      {:error, :already_exists} ->  %{error: room <> " already exists"}
    end

    {:reply, {:text, to_json(response)}, req, state}
  end

  defp to_json(response), do: Poison.encode!(response)
  defp from_json(json), do: Poison.decode!(json)
end