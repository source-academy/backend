defmodule Cadet.Chatbot.PromptBuilderTest do
  use ExUnit.Case

  alias Cadet.Chatbot.PromptBuilder

  describe "build_prompt/2" do
    test "includes section summary when available" do
      result = PromptBuilder.build_prompt("1.1.1", "Some paragraph text")
      assert is_binary(result)
      assert String.contains?(result, "Some paragraph text")
      assert String.contains?(result, "Here is the summary of this section")
    end

    test "handles missing section summary" do
      result = PromptBuilder.build_prompt("nonexistent_section", "Some paragraph text")
      assert is_binary(result)
      assert String.contains?(result, "Some paragraph text")
      assert String.contains?(result, "There is no section summary")
    end
  end

  describe "build_routing_prompt/2" do
    test "injects document map into prompt with placeholder" do
      docs = [%{"id" => 1, "title" => "Lecture 1"}]
      prompt = "Select docs from: %DOCUMENT_MAP%"

      assert {:ok, result} = PromptBuilder.build_routing_prompt(docs, prompt)
      assert String.contains?(result, "Lecture 1")
      refute String.contains?(result, "%DOCUMENT_MAP%")
    end

    test "returns error when prompt is missing placeholder" do
      docs = [%{"id" => 1, "title" => "Lecture 1"}]
      prompt = "Select relevant documents"

      assert {:error, :missing_document_map_placeholder} =
               PromptBuilder.build_routing_prompt(docs, prompt)
    end

    test "returns error when prompt is empty string" do
      assert {:error, :empty_routing_prompt} =
               PromptBuilder.build_routing_prompt([], "")
    end

    test "returns error when prompt is nil" do
      assert {:error, :empty_routing_prompt} =
               PromptBuilder.build_routing_prompt([], nil)
    end
  end
end
