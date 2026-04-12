defmodule Cadet.Chatbot.RagPipelineTest do
  use ExUnit.Case
  use ExVCR.Mock, adapter: ExVCR.Adapter.Hackney

  alias Cadet.Chatbot.RagPipeline

  @moduletag :serial

  setup_all do
    HTTPoison.start()
    # Ensure cache is clean
    Cadet.Chatbot.CourseDocuments.invalidate_cache()
    :ok
  end

  @default_opts [
    routing_prompt: "Select relevant docs from: %DOCUMENT_MAP%",
    answer_prompt: "You are a helpful tutor.",
    model: "gpt-4o"
  ]

  describe "process_rag_query/2" do
    test "returns :no_docs when document map is empty" do
      # With no document_map.json or empty one, should fall back
      Cadet.Chatbot.CourseDocuments.invalidate_cache()

      assert {:no_docs, "You are a helpful tutor."} =
               RagPipeline.process_rag_query("What is recursion?", @default_opts)
    end
  end
end
