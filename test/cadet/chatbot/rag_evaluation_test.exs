defmodule Cadet.Chatbot.RagEvaluationTest do
  use ExUnit.Case, async: true

  alias Cadet.Chatbot.{PromptBuilder, RagEvaluation}

  describe "cases/0" do
    test "defines valid simulated student questions across the whole textbook" do
      cases = RagEvaluation.cases()

      assert length(cases) >= 20
      assert Enum.all?(cases, &RagEvaluation.valid_case?/1)
      assert cases |> Enum.map(& &1.chapter) |> Enum.uniq() |> Enum.sort() == [1, 2, 3, 4, 5]
      assert Enum.any?(cases, &(&1.category == :edge_case))
      assert Enum.any?(cases, &(&1.difficulty == :hard))
    end

    test "uses unique ids" do
      ids = RagEvaluation.cases() |> Enum.map(& &1.id)

      assert Enum.uniq(ids) == ids
    end

    test "marks a focused subset as requiring section citations" do
      citation_cases = Enum.filter(RagEvaluation.cases(), & &1.require_section_reference)

      assert length(citation_cases) >= 10

      assert Enum.all?(citation_cases, fn case_data ->
               instruction = RagEvaluation.citation_instruction(case_data)

               String.contains?(instruction, "Evaluation requirement") and
                 Enum.any?(case_data.expected_sections, fn section ->
                   String.contains?(instruction, "Section #{section}")
                 end)
             end)
    end
  end

  describe "answer_mentions_expected_section?/2" do
    test "accepts exact expected section references" do
      case_data = %{
        expected_sections: ["3.4.2"],
        require_section_reference: true
      }

      assert RagEvaluation.answer_mentions_expected_section?(
               "This is a serialization issue. You can read more about it in Section 3.4.2.",
               case_data
             )
    end

    test "rejects nearby but different section references" do
      case_data = %{
        expected_sections: ["3.4.2"],
        require_section_reference: true
      }

      refute RagEvaluation.answer_mentions_expected_section?(
               "This is related to concurrency. You can read more about it in Section 3.4.",
               case_data
             )
    end

    test "accepts any expected section when a case has multiple targets" do
      case_data = %{
        expected_sections: ["3.2.2", "3.2.3"],
        require_section_reference: true
      }

      assert RagEvaluation.answer_mentions_expected_section?(
               "The closure carries its defining environment. See Section 3.2.3.",
               case_data
             )
    end
  end

  describe "retrieval_hits_expected_section?/2" do
    test "checks section metadata from atom and string keyed chunks" do
      case_data = %{expected_sections: ["2.5.2"]}

      chunks = [
        %{metadata: %{"section" => "2.4.3"}},
        %{"metadata" => %{section: "2.5.2"}}
      ]

      assert RagEvaluation.retrieval_hits_expected_section?(chunks, case_data)
    end
  end

  describe "prompt integration" do
    test "builds an evaluation prompt that contains retrieved section metadata and required citation instruction" do
      case_data =
        Enum.find(RagEvaluation.cases(), fn case_data ->
          case_data.id == "fermat_carmichael_false_positive"
        end)

      chunks = [
        %{
          title: "SICP Python",
          content: "Carmichael numbers can fool the Fermat test.",
          metadata: %{"section" => "1.2.6", "section_title" => "Example: Testing for Primality"}
        }
      ]

      prompt =
        PromptBuilder.build_prompt(case_data.current_section, "", chunks) <>
          RagEvaluation.citation_instruction(case_data)

      assert String.contains?(prompt, "Section: 1.2.6 Example: Testing for Primality")
      assert String.contains?(prompt, "explicitly mentions Section 1.2.6")
    end
  end
end
