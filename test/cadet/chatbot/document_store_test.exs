defmodule Cadet.Chatbot.DocumentStoreTest do
  use ExUnit.Case

  alias Cadet.Chatbot.DocumentStore

  describe "fetch_and_encode_documents/1" do
    test "returns empty list for empty input" do
      assert DocumentStore.fetch_and_encode_documents([]) == []
    end
  end
end
