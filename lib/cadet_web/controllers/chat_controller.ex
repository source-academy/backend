defmodule CadetWeb.ChatController do
  use CadetWeb, :controller

  use PhoenixSwagger

  swagger_path :chat do
    put("/chat")

    summary("A wrapper for client that send queries to LLMs")

    security([%{JWT: []}])

    consumes("application/json")

    parameters do
      message(
        :body,
        :list,
        "Conversation history. Need to be an non empty list of format {role: string, content:string}. For more details, refer to https://platform.openai.com/docs/api-reference/chat/create"
      )
    end

    response(200, "OK")
    response(400, "Missing or invalid parameter(s)")
    response(401, "Unauthorized")
    response(500, "When OpenAI API returns an error")
  end

  def chat(conn, %{
        "context" => m,
        "conversationId" => _conversationId,
        "userMessage" => _userMessage
      }) do
    user = conn.assigns.current_user

    case m do
      nil ->
        send_resp(conn, :bad_request, "Request must be in JSON format")

      _ ->
        case is_message_list?(m) do
          true ->
            case OpenAI.chat_completion(model: "gpt-4", messages: convert(m)) do
              {:ok, result_map} ->
                choices = Map.get(result_map, :choices, [])
                resp = Enum.at(choices, 0)["message"]["content"]
                send_resp(conn, :ok, resp)

              {:error, reason} ->
                error_message = reason["error"]["message"]
                IO.puts("Error message from openAI response: #{error_message}")
                IO.puts("Arguement that leads to this error:\n#{convert_to_string(m)}")
                internal_error = 500
                send_resp(conn, internal_error, error_message)
            end

          false ->
            send_resp(
              conn,
              :bad_request,
              "Request must be a non empty list of message of format: {role:string, content:string}"
            )
        end
    end
  end

  defp is_message_list?(list) do
    is_list(list) &&
      Enum.all?(list, fn
        %{"content" => _content, "role" => _role} -> true
        _ -> false
      end) &&
      length(list) > 0
  end

  defp convert(list) do
    Enum.map(list, fn %{"content" => content, "role" => role} ->
      %{role: role, content: content}
    end)
  end

  defp convert_to_string(list) do
    Enum.map_join(list, fn %{"content" => content, "role" => role} ->
      "role: #{role}, content: #{content} \n"
    end)
  end
end
