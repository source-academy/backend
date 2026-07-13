defmodule Cadet.Chatbot.VectorRag do
  @moduledoc false

  @language "python"

  def enabled? do
    config(:enabled, false)
  end

  def retriever do
    config(:retriever, Cadet.Chatbot.VectorRetriever)
  end

  def embedding_provider do
    config(:embedding_provider, Cadet.Chatbot.OpenAIEmbeddings)
  end

  def embedding_model do
    config(:embedding_model, "text-embedding-3-small")
  end

  def embedding_api_url do
    config(:embedding_api_url, "https://api.openai.com/v1/embeddings")
  end

  def top_k do
    config(:top_k, 5)
  end

  def min_similarity do
    config(:min_similarity, nil)
  end

  def debug? do
    config(:debug, false)
  end

  def language, do: @language

  def valid_language?(language), do: language == @language

  defp config(key, default) do
    :cadet
    |> Application.get_env(:vector_rag, [])
    |> Keyword.get(key, default)
  end
end
