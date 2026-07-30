defmodule Cadet.Chatbot.OpenAIEmbeddings do
  @moduledoc """
  OpenAI embeddings client used by vector RAG retrieval.
  """

  @behaviour Cadet.Chatbot.Embeddings

  alias Cadet.Chatbot.VectorRag

  @impl true
  def embed(text) when is_binary(text) do
    api_key = Application.get_env(:openai, :api_key) || System.get_env("OPENAI_API_KEY")

    if is_nil(api_key) or api_key == "" do
      {:error, :missing_openai_api_key}
    else
      body =
        Jason.encode!(%{
          input: text,
          model: VectorRag.embedding_model()
        })

      headers = [
        {"Authorization", "Bearer #{api_key}"},
        {"Content-Type", "application/json"}
      ]

      case HTTPoison.post(VectorRag.embedding_api_url(), body, headers,
             timeout: 30_000,
             recv_timeout: 60_000
           ) do
        {:ok, %{status_code: status, body: response_body}} when status in 200..299 ->
          parse_embedding_response(response_body)

        {:ok, %{status_code: status, body: response_body}} ->
          {:error, {:openai_embeddings_error, status, response_body}}

        {:error, reason} ->
          {:error, reason}
      end
    end
  end

  defp parse_embedding_response(response_body) do
    with {:ok, %{"data" => [%{"embedding" => embedding} | _]}} <- Jason.decode(response_body),
         true <- is_list(embedding) do
      {:ok, Enum.map(embedding, &(&1 * 1.0))}
    else
      _ -> {:error, :invalid_openai_embeddings_response}
    end
  end
end
