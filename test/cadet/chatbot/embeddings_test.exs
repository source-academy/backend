defmodule Cadet.Chatbot.EmbeddingsTest.FakeProvider do
  @behaviour Cadet.Chatbot.Embeddings

  @impl true
  def embed(text), do: {:ok, [String.length(text) * 1.0]}
end

defmodule Cadet.Chatbot.EmbeddingsTest do
  use ExUnit.Case

  alias Cadet.Chatbot.Embeddings

  test "delegates to the configured embedding provider" do
    original_config = Application.get_env(:cadet, :vector_rag)

    Application.put_env(:cadet, :vector_rag,
      embedding_provider: Cadet.Chatbot.EmbeddingsTest.FakeProvider
    )

    on_exit(fn -> Application.put_env(:cadet, :vector_rag, original_config) end)

    assert Embeddings.embed("hello") == {:ok, [5.0]}
  end
end
