defmodule CadetWeb.ChatController do
  @moduledoc """
  Handles the chatbot conversation API endpoints.
  """
  use CadetWeb, :controller
  use PhoenixSwagger
  require Logger

  alias Cadet.Chatbot.{Conversation, LlmConversations}
  @max_content_size 1000

  def init_chat(conn, %{"section" => section, "initialContext" => initialContext}) do
    user = conn.assigns.current_user
    Logger.info("ChatController.init_chat: user_id=#{user.id} section=#{section}")

    if is_nil(section) do
      Logger.warning("ChatController.init_chat: missing section user_id=#{user.id}")
      send_resp(conn, :bad_request, "Missing course section")
    else
      case LlmConversations.create_conversation(user.id, section, initialContext) do
        {:ok, conversation} ->
          Logger.info("ChatController.init_chat: success user_id=#{user.id} conversation_id=#{conversation.id}")
          conn
          |> put_status(:created)
          |> render(
            "conversation_init.json",
            %{
              conversation_id: conversation.id,
              last_message: conversation.messages |> List.last(),
              max_content_size: @max_content_size
            }
          )

        {:error, error_message} ->
          Logger.error("ChatController.init_chat: error user_id=#{user.id} error=#{error_message}")
          send_resp(conn, :unprocessable_entity, error_message)
      end
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
    response(422, "Message exceeds the maximum allowed length")
    response(500, "When OpenAI API returns an error")
  end

  def chat(conn, %{"conversationId" => conversation_id, "message" => user_message}) do
    user = conn.assigns.current_user
    Logger.info("ChatController.chat: user_id=#{user.id} conversation_id=#{conversation_id} message_length=#{String.length(user_message)}")

    with true <- String.length(user_message) <= @max_content_size || {:error, :message_too_long},
         {:ok, conversation} <-
           LlmConversations.get_conversation_for_user(user.id, conversation_id),
         {:ok, updated_conversation} <-
           LlmConversations.add_message(conversation, "user", user_message),
         payload <- generate_payload(updated_conversation) do
      case OpenAI.chat_completion(model: "gpt-4", messages: payload) do
        {:ok, result_map} ->
          choices = Map.get(result_map, :choices, [])
          bot_message = Enum.at(choices, 0)["message"]["content"]

          case LlmConversations.add_message(updated_conversation, "assistant", bot_message) do
            {:ok, _} ->
              Logger.info("ChatController.chat: success user_id=#{user.id} conversation_id=#{conversation_id}")
              render(conn, "conversation.json", %{
                conversation_id: conversation_id,
                response: bot_message
              })

            {:error, error_message} ->
              Logger.error("ChatController.chat: db_error user_id=#{user.id} error=#{error_message}")
              send_resp(conn, 500, error_message)
          end

        {:error, reason} ->
          error_message = reason["error"]["message"]
          Logger.error("ChatController.chat: openai_error user_id=#{user.id} error=#{error_message}")
          IO.puts("Error message from openAI response: #{error_message}")
          LlmConversations.add_error_message(updated_conversation)
          send_resp(conn, 500, error_message)
      end
    else
      {:error, :message_too_long} ->
        Logger.warning("ChatController.chat: message_too_long user_id=#{user.id} length=#{String.length(user_message)}")
        send_resp(
          conn,
          :unprocessable_entity,
          "Message exceeds the maximum allowed length of #{@max_content_size}"
        )

      {:error, {:not_found, error_message}} ->
        Logger.warning("ChatController.chat: not_found user_id=#{user.id} conversation_id=#{conversation_id}")
        send_resp(conn, :not_found, error_message)

      {:error, error_message} ->
        Logger.error("ChatController.chat: error user_id=#{user.id} error=#{error_message}")
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
      |> Enum.map(&Map.take(&1, [:role, :content, "role", "content"]))
      |> Enum.reverse()

    conversation.prepend_context ++ messages_payload
  end

  def max_content_length, do: @max_content_size
end
