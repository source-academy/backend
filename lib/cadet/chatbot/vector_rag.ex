defmodule Cadet.Chatbot.VectorRag do
  @moduledoc false

  @languages ~w(javascript python)

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

  def normalize_language(nil), do: "javascript"

  def normalize_language(language) when is_binary(language) do
    language
    |> String.downcase()
    |> case do
      "js" -> "javascript"
      "javascript" -> "javascript"
      "source" -> "javascript"
      "source_js" -> "javascript"
      "python" -> "python"
      "py" -> "python"
      _ -> nil
    end
  end

  def normalize_language(_language), do: nil

  def valid_language?(language), do: language in @languages

  defp config(key, default) do
    :cadet
    |> Application.get_env(:vector_rag, [])
    |> Keyword.get(key, default)
  end
end
