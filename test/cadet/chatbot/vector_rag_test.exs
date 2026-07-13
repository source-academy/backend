defmodule Cadet.Chatbot.VectorRagTest do
  use ExUnit.Case

  alias Cadet.Chatbot.VectorRag

  describe "normalize_language/1" do
    test "defaults missing language to javascript" do
      assert VectorRag.normalize_language(nil) == "javascript"
    end

    test "normalizes common aliases" do
      assert VectorRag.normalize_language("JS") == "javascript"
      assert VectorRag.normalize_language("source") == "javascript"
      assert VectorRag.normalize_language("py") == "python"
    end

    test "rejects unsupported languages" do
      assert VectorRag.normalize_language("ruby") == nil
    end
  end
end
