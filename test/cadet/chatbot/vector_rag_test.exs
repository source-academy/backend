defmodule Cadet.Chatbot.VectorRagTest do
  use ExUnit.Case

  alias Cadet.Chatbot.VectorRag

  describe "language/0" do
    test "uses python as the only internal retrieval language" do
      assert VectorRag.language() == "python"
      assert VectorRag.valid_language?("python")
      refute VectorRag.valid_language?("javascript")
      refute VectorRag.valid_language?("source")
    end
  end
end
