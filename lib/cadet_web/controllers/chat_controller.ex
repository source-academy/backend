defmodule CadetWeb.ChatController do
  @moduledoc """
  Handles the chatbot conversation API endpoints.
  Each user has exactly one conversation.
  """
  use CadetWeb, :controller
  use PhoenixSwagger
  require Logger

  alias Cadet.Chatbot.{Conversation, LlmConversations}
  @max_content_size 1000

  def init_chat(conn, _params) do
    user = conn.assigns.current_user
    Logger.info("Initializing chat for user #{user.id}")

    # Get existing conversation for user or create a new one (one per user)
    case LlmConversations.get_or_create_conversation(user.id) do
      {:ok, conversation} ->
        Logger.info(
          "Chat initialized successfully for user #{user.id}. Conversation ID: #{conversation.id}."
        )

        conn
        |> put_status(:ok)
        |> render("conversation_init.json", %{
          conversation_id: conversation.id,
          messages: conversation.messages,
          max_content_size: @max_content_size
        })

      {:error, error_message} ->
        Logger.error("Failed to initialize chat for user #{user.id}. Error: #{error_message}.")
        send_resp(conn, :unprocessable_entity, error_message)
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
        "User message to send to the chatbot. Each user has a single conversation that is automatically used."
      )
    end

    response(200, "OK")
    response(400, "Missing or invalid parameter(s)")
    response(401, "Unauthorized")
    response(404, "No conversation found for user")
    response(422, "Message exceeds the maximum allowed length")
    response(500, "When OpenAI API returns an error")
  end

  def chat(conn, %{
        "message" => user_message,
        "section" => section,
        "initialContext" => visible_text
      }) do
    user = conn.assigns.current_user

    Logger.info(
      "Processing chat message for user #{user.id}. Message length: #{String.length(user_message)}."
    )

    # User is locked to a single conversation - fetch it by user_id only
    with true <- String.length(user_message) <= @max_content_size || {:error, :message_too_long},
         {:ok, conversation} <- LlmConversations.get_conversation_for_user(user.id),
         {:ok, updated_conversation} <-
           LlmConversations.add_message(conversation, "user", user_message),
         system_prompt <- Cadet.Chatbot.PromptBuilder.build_prompt(section, visible_text),
         payload <- generate_payload(updated_conversation, system_prompt) do
      case OpenAI.chat_completion(model: "gpt-4", messages: payload) do
        {:ok, result_map} ->
          choices = Map.get(result_map, :choices, [])
          bot_message = Enum.at(choices, 0)["message"]["content"]

          case LlmConversations.add_message(updated_conversation, "assistant", bot_message) do
            {:ok, _} ->
              Logger.info(
                "Chat message processed successfully for user #{user.id}, conversation #{conversation.id}."
              )

              render(conn, "conversation.json", %{
                conversation_id: conversation.id,
                response: bot_message
              })

            {:error, error_message} ->
              Logger.error(
                "Failed to save bot response for user #{user.id}, conversation #{conversation.id}: #{error_message}."
              )

              send_resp(conn, 500, error_message)
          end

        {:error, reason} ->
          error_message = reason["error"]["message"]

          Logger.error(
            "OpenAI API error for user #{user.id}, conversation #{conversation.id}: #{error_message}."
          )

          LlmConversations.add_error_message(updated_conversation)
          send_resp(conn, 500, error_message)
      end
    else
      {:error, :message_too_long} ->
        Logger.error(
          "Message too long for user #{user.id}. Length: #{String.length(user_message)}."
        )

        send_resp(
          conn,
          :unprocessable_entity,
          "Message exceeds the maximum allowed length of #{@max_content_size}"
        )

      {:error, {:not_found, error_message}} ->
        Logger.error("No conversation found for user #{user.id}. User must init_chat first.")

        send_resp(conn, :not_found, error_message)

      {:error, error_message} ->
        Logger.error("An error occurred for user #{user.id}. Error: #{error_message}.")
        send_resp(conn, 500, error_message)
    end
  end

  @context_size 10

  @spec generate_payload(Conversation.t(), String.t()) :: list(map())
  defp generate_payload(conversation, system_prompt) do
    system_context = [%{role: "system", content: system_prompt}]
    # Only get the last 10 messages into the context
    messages_payload =
      conversation.messages
      |> Enum.reverse()
      |> Enum.take(@context_size)
      |> Enum.map(&Map.take(&1, [:role, :content, "role", "content"]))
      |> Enum.reverse()

    system_context ++ messages_payload
  end

  def max_content_length, do: @max_content_size
end
