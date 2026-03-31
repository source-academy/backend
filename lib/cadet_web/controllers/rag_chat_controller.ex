defmodule CadetWeb.RagChatController do
  use CadetWeb, :controller
  require Logger

  alias Cadet.Chatbot.{Conversation, LlmConversations, RagConversations, RagPipeline}
  alias Cadet.Courses.Course
  alias Cadet.Repo
  @max_content_size 1000
  @context_size 10

  def init_chat(conn, _params) do
    user = conn.assigns.current_user
    Logger.info("Initializing RAG chat for user #{user.id}")

    case RagConversations.get_or_create_conversation(user.id) do
      {:ok, conversation} ->
        Logger.info("RAG chat initialized for user #{user.id}. Conversation: #{conversation.id}")

        conn
        |> put_status(:ok)
        |> render("conversation_init.json", %{
          conversation_id: conversation.id,
          messages: conversation.messages,
          max_content_size: @max_content_size
        })

      {:error, error_message} ->
        Logger.error("Failed to init RAG chat for user #{user.id}: #{error_message}")
        send_resp(conn, :unprocessable_entity, error_message)
    end
  end

  def chat(conn, %{"message" => user_message}) when is_binary(user_message) do
    user = conn.assigns.current_user

    Logger.info("Processing RAG chat for user #{user.id}. Length: #{String.length(user_message)}")
    Logger.info("User latest_viewed_course_id: #{inspect(user.latest_viewed_course_id)}")

    course =
      if user.latest_viewed_course_id,
        do: Repo.get(Course, user.latest_viewed_course_id),
        else: nil

    Logger.info("Course found: #{inspect(course != nil)}")
    Logger.info("Answer prompt from DB: #{inspect(course && course.pixelbot_answer_prompt)}")

    rag_opts = [
      routing_prompt: (course && course.pixelbot_routing_prompt) || "",
      answer_prompt: (course && course.pixelbot_answer_prompt) || ""
    ]

    with true <- String.length(user_message) <= @max_content_size || {:error, :message_too_long},
         {:ok, conversation} <- RagConversations.get_conversation_for_user(user.id),
         {:ok, updated_conversation} <-
           LlmConversations.add_message(conversation, "user", user_message) do
      case RagPipeline.process_rag_query(user_message, rag_opts) do
        {:rag, system_prompt, pdf_attachments} ->
          payload = generate_payload(updated_conversation, system_prompt, pdf_attachments)
          handle_openai_call(conn, payload, updated_conversation, conversation.id)

        {:no_docs, system_prompt} ->
          payload = generate_fallback_payload(updated_conversation, system_prompt)
          handle_openai_call(conn, payload, updated_conversation, conversation.id)
      end
    else
      {:error, :message_too_long} ->
        send_resp(
          conn,
          :unprocessable_entity,
          "Message exceeds the maximum allowed length of #{@max_content_size}"
        )

      {:error, {:not_found, error_message}} ->
        send_resp(conn, :not_found, error_message)

      {:error, error_message} ->
        send_resp(conn, 500, error_message)
    end
  end

  def chat(conn, _params) do
    send_resp(conn, :bad_request, "Missing or invalid parameter(s)")
  end

  defp handle_openai_call(conn, payload, updated_conversation, conversation_id) do
    case OpenAI.chat_completion(model: "gpt-4o", messages: payload) do
      {:ok, result_map} ->
        choices = Map.get(result_map, :choices, [])

        bot_message =
          case choices do
            [first | _] -> first["message"]["content"]
            _ -> nil
          end

        if is_nil(bot_message) do
          Logger.error("OpenAI returned empty choices for RAG chat")
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
              send_resp(conn, 500, error_message)
          end
        end

      {:error, reason} ->
        error_message = get_in(reason, ["error", "message"]) || "Unknown OpenAI error"
        Logger.error("OpenAI API error in RAG chat: #{error_message}")
        LlmConversations.add_error_message(updated_conversation)
        send_resp(conn, 500, error_message)
    end
  end

  defp generate_fallback_payload(%Conversation{} = conversation, system_prompt) do
    system_context = [%{role: "system", content: system_prompt}]

    messages_payload =
      conversation.messages
      |> Enum.reverse()
      |> Enum.take(@context_size)
      |> Enum.map(&Map.take(&1, [:role, :content, "role", "content"]))
      |> Enum.reverse()

    {earlier_messages, last_message} =
      case Enum.split(messages_payload, -1) do
        {earlier, [last]} -> {earlier, [last]}
        {[], []} -> {[], []}
      end

    system_reminder = [%{role: "system", content: system_prompt}]

    system_context ++ earlier_messages ++ system_reminder ++ last_message
  end

  defp generate_payload(%Conversation{} = conversation, system_prompt, pdf_attachments) do
    system_context = [%{role: "system", content: system_prompt}]

    messages_payload =
      conversation.messages
      |> Enum.reverse()
      |> Enum.take(@context_size)
      |> Enum.map(&Map.take(&1, [:role, :content, "role", "content"]))
      |> Enum.reverse()

    # Attach PDFs to the last user message as multimodal content
    {earlier_messages, last_message} =
      case Enum.split(messages_payload, -1) do
        {earlier, [last]} -> {earlier, last}
        {[], []} -> {[], %{"role" => "user", "content" => ""}}
      end

    user_text = last_message[:content] || last_message["content"] || ""

    pdf_content_blocks =
      Enum.map(pdf_attachments, fn att ->
        %{
          type: "file",
          file: %{
            filename: att.title,
            file_data: "data:#{att.media_type};base64,#{att.base64}"
          }
        }
      end)

    multimodal_message = %{
      role: "user",
      content: [%{type: "text", text: user_text}] ++ pdf_content_blocks
    }

    system_reminder = [%{role: "system", content: system_prompt}]

    system_context ++ earlier_messages ++ system_reminder ++ [multimodal_message]
  end
end
