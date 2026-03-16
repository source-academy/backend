defmodule Cadet.Chatbot.RagPipeline do
  @moduledoc """
  Orchestrates the two-pass RAG flow:
  1. Routing LLM call — picks relevant documents from the document map
  2. Fetch PDFs from S3 and base64-encode them
  3. Return the RAG answer prompt + PDF attachments for the answer LLM call
  """

  require Logger

  alias Cadet.Chatbot.{CourseDocuments, DocumentStore, PromptBuilder}

  @doc """
  Runs the RAG pipeline for a user message.

  Returns:
  - {:rag, system_prompt, pdf_attachments} when relevant documents are found
  - {:fallback} when no documents are relevant or the pipeline fails
  """
  def process_rag_query(user_message) do
    document_map = CourseDocuments.build_document_map_json()

    if document_map == [] do
      Logger.info("RAG pipeline: no documents in map, falling back")
      {:fallback}
    else
      run_routing(user_message, document_map)
    end
  end

  defp run_routing(user_message, document_map) do
    routing_prompt = PromptBuilder.build_routing_prompt(document_map)

    payload = [
      %{role: "system", content: routing_prompt},
      %{role: "user", content: user_message}
    ]

    Logger.info("RAG pipeline: calling routing LLM with #{length(document_map)} documents in map")

    case OpenAI.chat_completion(model: "gpt-4o", messages: payload) do
      {:ok, result_map} ->
        result_map
        |> extract_routing_response()
        |> handle_routing_result()

      {:error, reason} ->
        Logger.error("RAG pipeline: routing LLM call failed: #{inspect(reason)}")
        {:fallback}
    end
  end

  defp extract_routing_response(result_map) do
    choices = Map.get(result_map, :choices, [])

    content =
      case choices do
        [first | _] -> first["message"]["content"]
        _ -> nil
      end

    if is_nil(content) do
      Logger.error("RAG pipeline: routing LLM returned empty choices")
      {:error, :empty_response}
    else
      parse_doc_ids(content)
    end
  end

  defp parse_doc_ids(content) do
    trimmed = String.trim(content)

    case Jason.decode(trimmed) do
      {:ok, ids} when is_list(ids) ->
        Logger.info(
          "RAG pipeline: routing LLM selected #{length(ids)} documents: #{inspect(ids)}"
        )

        {:ok, ids}

      _ ->
        case Regex.run(~r/\[.*\]/s, trimmed) do
          [json_str] ->
            case Jason.decode(json_str) do
              {:ok, ids} when is_list(ids) ->
                Logger.info("RAG pipeline: extracted #{length(ids)} doc IDs from response")
                {:ok, ids}

              _ ->
                Logger.error("RAG pipeline: could not parse routing response: #{trimmed}")
                {:error, :parse_error}
            end

          nil ->
            Logger.error("RAG pipeline: no JSON array found in routing response: #{trimmed}")
            {:error, :parse_error}
        end
    end
  end

  defp handle_routing_result({:ok, []}) do
    Logger.info("RAG pipeline: no relevant documents selected")
    {:fallback}
  end

  defp handle_routing_result({:ok, doc_ids}) do
    documents = CourseDocuments.get_documents_by_ids(doc_ids)

    if documents == [] do
      Logger.warning("RAG pipeline: routing returned IDs but none matched document map")
      {:fallback}
    else
      Logger.info("RAG pipeline: fetching #{length(documents)} documents from S3")
      pdf_attachments = DocumentStore.fetch_and_encode_documents(documents)

      if pdf_attachments == [] do
        Logger.warning("RAG pipeline: all document fetches failed, falling back")
        {:fallback}
      else
        rag_prompt = PromptBuilder.build_rag_answer_prompt()
        {:rag, rag_prompt, pdf_attachments}
      end
    end
  end

  defp handle_routing_result({:error, _}) do
    {:fallback}
  end
end
