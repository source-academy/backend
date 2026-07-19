defmodule CadetWeb.ChatController do
  @moduledoc """
  Handles the chatbot conversation API endpoints.
  Each user has exactly one conversation.
  """
  use CadetWeb, :controller
  use PhoenixSwagger
  require Logger

  alias Cadet.Chatbot.{Conversation, LanguageDirectory, LlmConversations, SicpNotesPy, VectorRag}
  @max_content_size 1000
  @openai_http_options [timeout: 60_000, recv_timeout: 60_000]

  def init_chat(conn, params) do
    user = conn.assigns.current_user
    Logger.info("Initializing chat for user #{user.id}")

    with {:ok, language_id} <- validate_language_id(Map.get(params, "languageId")),
         {:ok, conversation} <-
           LlmConversations.get_or_create_conversation(user.id, %{language_id: language_id}) do
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
    else
      {:error, :unsupported_language} ->
        send_resp(conn, :bad_request, "Unsupported languageId")

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

  def chat(conn, %{"message" => user_message} = params) when is_binary(user_message) do
    user = conn.assigns.current_user
    section = Map.get(params, "section")
    visible_text = Map.get(params, "initialContext", "")
    language_id = Map.get(params, "languageId")
    conversation_id = Map.get(params, "conversationId")

    Logger.info(
      "Processing chat message for user #{user.id}. Message length: #{String.length(user_message)}."
    )

    with :ok <- validate_optional_string(section),
         :ok <- validate_optional_string(visible_text),
         :ok <- validate_optional_conversation_id(conversation_id),
         {:ok, language_id} <- validate_language_id(language_id),
         true <- String.length(user_message) <= @max_content_size || {:error, :message_too_long},
         {:ok, conversation} <- LlmConversations.get_conversation_for_user(user.id),
         :ok <- validate_conversation_id(conversation, conversation_id),
         {:ok, conversation} <- maybe_update_language(conversation, language_id),
         {:ok, updated_conversation} <-
           LlmConversations.add_message(conversation, "user", user_message),
         retrieved_chunks <- retrieve_chunks(user, user_message, visible_text || ""),
         :ok <-
           ensure_textbook_context(
             section,
             visible_text || "",
             retrieved_chunks,
             updated_conversation,
             conversation.id
           ),
         system_prompt <-
           Cadet.Chatbot.PromptBuilder.build_prompt(
             section,
             visible_text || "",
             retrieved_chunks
           ),
         payload <- generate_payload(updated_conversation, system_prompt) do
      handle_openai_call(conn, payload, updated_conversation, conversation.id)
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

      {:error, :unsupported_language} ->
        send_resp(conn, :bad_request, "Unsupported languageId")

      {:error, :invalid_conversation} ->
        send_resp(conn, :not_found, "Conversation not found")

      {:error, {:off_scope, off_scope_conversation, off_scope_conversation_id}} ->
        handle_off_scope_message(conn, off_scope_conversation, off_scope_conversation_id)

      :error ->
        send_resp(conn, :bad_request, "Missing or invalid parameter(s)")

      {:error, {:not_found, error_message}} ->
        Logger.error("No conversation found for user #{user.id}. User must init_chat first.")

        send_resp(conn, :not_found, error_message)

      {:error, error_message} ->
        Logger.error("An error occurred for user #{user.id}. Error: #{error_message}.")
        send_resp(conn, 500, error_message)
    end
  end

  def chat(conn, _params) do
    Logger.error("Chat request failed due to missing parameters.")
    send_resp(conn, :bad_request, "Missing or invalid parameter(s)")
  end

  defp retrieve_chunks(user, user_message, visible_text) do
    query = build_retrieval_query(user_message, visible_text)

    case VectorRag.retriever().retrieve(query,
           course_id: user.latest_viewed_course_id,
           language: VectorRag.language(),
           limit: VectorRag.top_k()
         ) do
      {:ok, chunks} ->
        chunks

      {:error, reason} ->
        Logger.error("Vector RAG retrieval failed: #{inspect(reason)}")
        []
    end
  end

  defp build_retrieval_query(user_message, visible_text) do
    [user_message, visible_text]
    |> Enum.join("\n\n")
    |> String.slice(0, 2_000)
  end

  defp ensure_textbook_context(section, visible_text, retrieved_chunks, conversation, conversation_id) do
    if !VectorRag.enabled?() || textbook_context_available?(section, visible_text, retrieved_chunks) do
      :ok
    else
      {:error, {:off_scope, conversation, conversation_id}}
    end
  end

  defp textbook_context_available?(section, visible_text, retrieved_chunks) do
    String.trim(visible_text) != "" ||
      retrieved_chunks != [] ||
      !is_nil(SicpNotesPy.get_summary(section))
  end

  defp handle_off_scope_message(conn, conversation, conversation_id) do
    bot_message =
      "I can only help with questions related to the Python textbook material. " <>
        "Please ask a textbook-related question."

    case LlmConversations.add_message(conversation, "assistant", bot_message) do
      {:ok, _} ->
        render(conn, "conversation.json", %{
          conversation_id: conversation_id,
          response: bot_message
        })

      {:error, error_message} ->
        Logger.error("Failed to save off-scope bot response: #{error_message}")
        send_resp(conn, 500, error_message)
    end
  end

  defp validate_language_id(nil), do: {:ok, nil}

  defp validate_language_id(language_id) when is_binary(language_id) do
    if LanguageDirectory.sicpy_language?(language_id) do
      {:ok, language_id}
    else
      {:error, :unsupported_language}
    end
  end

  defp validate_language_id(_language_id), do: {:error, :unsupported_language}

  defp validate_optional_string(nil), do: :ok
  defp validate_optional_string(value) when is_binary(value), do: :ok
  defp validate_optional_string(_value), do: :error

  defp validate_optional_conversation_id(nil), do: :ok

  defp validate_optional_conversation_id(value) when is_binary(value) or is_integer(value),
    do: :ok

  defp validate_optional_conversation_id(_value), do: :error

  defp validate_conversation_id(_conversation, nil), do: :ok

  defp validate_conversation_id(conversation, conversation_id) do
    if to_string(conversation.id) == to_string(conversation_id),
      do: :ok,
      else: {:error, :invalid_conversation}
  end

  defp maybe_update_language(conversation, nil), do: {:ok, conversation}

  defp maybe_update_language(conversation, language_id) do
    LlmConversations.update_language(conversation, language_id)
  end

  defp handle_openai_call(conn, payload, updated_conversation, conversation_id) do
    openai_config = %OpenAI.Config{http_options: @openai_http_options}

    case OpenAI.chat_completion([model: "gpt-4", messages: payload], openai_config) do
      {:ok, result_map} ->
        choices = Map.get(result_map, :choices, [])

        bot_message =
          case choices do
            [first | _] -> first["message"]["content"]
            _ -> nil
          end

        if is_nil(bot_message) do
          Logger.error("OpenAI returned empty choices")
          LlmConversations.add_error_message(updated_conversation)
          send_resp(conn, 500, "No response from AI")
        else
          case LlmConversations.add_message(updated_conversation, "assistant", bot_message) do
            {:ok, _} ->
              render(conn, "conversation.json", %{
                conversation_id: conversation_id,
                response: bot_message
              })

            {:error, error_message} ->
              Logger.error("Failed to save bot response: #{error_message}")
              send_resp(conn, 500, error_message)
          end
        end

      {:error, reason} ->
        error_message = get_in(reason, ["error", "message"]) || "Unknown OpenAI error"
        Logger.error("OpenAI API error: #{error_message}")
        LlmConversations.add_error_message(updated_conversation)
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
