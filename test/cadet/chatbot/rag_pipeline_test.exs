defmodule Cadet.Chatbot.RagPipelineTest do
  use Cadet.DataCase
  use ExVCR.Mock, adapter: ExVCR.Adapter.Hackney

  alias Cadet.Chatbot.RagPipeline

  @moduletag :serial

  setup_all do
    HTTPoison.start()
    :ok
  end

  describe "process_rag_query/2" do
    test "returns :no_docs when the course has no documents" do
      course = insert(:course)

      opts = [
        routing_prompt: "Select relevant docs from: %DOCUMENT_MAP%",
        answer_prompt: "You are a helpful tutor.",
        model: "gpt-4o",
        course_id: course.id
      ]

      assert {:no_docs, "You are a helpful tutor."} =
               RagPipeline.process_rag_query("What is recursion?", opts)
    end
  end
end
