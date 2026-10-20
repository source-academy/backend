defmodule Cadet.Chatbot.Embeddings do
  @moduledoc """
  Thin wrapper around the configured embedding provider.
  """

  alias Cadet.Chatbot.VectorRag

  @callback embed(String.t()) :: {:ok, [float()]} | {:error, term()}

  def embed(text) when is_binary(text) do
    VectorRag.embedding_provider().embed(text)
  end
end
