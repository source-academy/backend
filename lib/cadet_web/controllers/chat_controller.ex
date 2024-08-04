defmodule CadetWeb.ChatController do
  @moduledoc """
  Handles the chatbot conversation API endpoints.
  """
  use CadetWeb, :controller
  use PhoenixSwagger

  alias Cadet.Chatbot.LlmConversations

  def init_chat(conn, %{"section" => section, "initialContext" => initialContext}) do
    user = conn.assigns.current_user

    cond do
      is_nil(section) ->
        send_resp(conn, :bad_request, "Request must be in JSON format")

      # Match '\d', '\d\.\d', or '\d\.\d\.\d' to get the course section
      String.match?(section, ~r/^\d+(\.\d+){0,2}$/) ->
        case LlmConversations.create_conversation(user.id, section, initialContext) do
          {:ok, conversation} ->
            conn
            |> put_status(:created)
            |> render(
              "conversation_init.json",
              %{
                conversation_id: conversation.id,
                last_message: conversation.messages |> List.last()
              }
            )

          {:error, error_message} ->
            send_resp(conn, :unprocessable_entity, error_message)
        end

      true ->
        send_resp(conn, :bad_request, "Invalid course section")
    end
  end

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

  def chat(conn, %{"conversationId" => conversation_id, "message" => user_message}) do
    user = conn.assigns.current_user

    with {:ok, conversation} <-
           LlmConversations.get_conversation_for_user(user.id, conversation_id),
         {:ok, updated_conversation} <-
           LlmConversations.add_message(conversation, "user", user_message),
         payload <- generate_payload(updated_conversation.messages) do
      case LlmConversations.add_message(updated_conversation, "bot", "Some test response") do
        {:ok, conversation_with_response} ->
          render(conn, "conversation.json", %{
            conversation_id: conversation_id,
            response: conversation_with_response.messages
          })

        {:error, error_message} ->
          send_resp(conn, 500, error_message)
      end

      # case OpenAI.chat_completion(model: "gpt-4", messages: payload) do
      #   {:ok, result_map} ->
      #     choices = Map.get(result_map, :choices, [])
      #     bot_message = Enum.at(choices, 0)["message"]["content"]

      #     case LlmConversations.add_message(updated_conversation, "bot", bot_message) do
      #       {:ok, _} ->
      #         send_resp(conn, :ok, bot_message)

      #       {:error, error_message} ->
      #         send_resp(conn, 500, error_message)
      #     end

      #   {:error, reason} ->
      #     error_message = reason["error"]["message"]
      #     IO.puts("Error message from openAI response: #{error_message}")
      #     send_resp(conn, 500, error_message)
      # end
    else
      {:error, error_message} ->
        send_resp(conn, 500, error_message)
    end
  end

  @context_size 20

  @spec generate_payload(Conversation.t()) :: list(map())
  defp generate_payload(conversation) do
    # Only get the last 20 messages into the context
    messages_payload =
      conversation.messages
      |> Enum.reverse()
      |> Enum.take(@context_size)
      |> Enum.reverse()

    conversation.prepend_context ++ messages_payload
  end
end
