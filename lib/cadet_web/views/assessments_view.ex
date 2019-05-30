defmodule CadetWeb.AssessmentsView do
  use CadetWeb, :view
  use Timex

  @graded_assessment_types ~w(mission sidequest contest)a

  def render("index.json", %{assessments: assessments}) do
    render_many(assessments, CadetWeb.AssessmentsView, "overview.json", as: :assessment)
  end

  def render("overview.json", %{assessment: assessment}) do
    transform_map_for_view(assessment, %{
      id: :id,
      title: :title,
      shortSummary: :summary_short,
      openAt: &format_datetime(&1.open_at),
      closeAt: &format_datetime(&1.close_at),
      type: :type,
      story: :story,
      number: :number,
      reading: :reading,
      status: &(&1.user_status || "not_attempted"),
      gradingStatus: &(&1.grading_status || "none"),
      maxGrade: :max_grade,
      maxXp: :max_xp,
      xp: &(&1.xp || 0),
      grade: &(&1.grade || 0),
      coverImage: :cover_picture
    })
  end

  def render("show.json", %{assessment: assessment}) do
    transform_map_for_view(
      assessment,
      %{
        id: :id,
        title: :title,
        type: :type,
        story: :story,
        number: :number,
        reading: :reading,
        longSummary: :summary_long,
        missionPDF: &Cadet.Assessments.Upload.url({&1.mission_pdf, &1}),
        questions:
          &Enum.map(&1.questions, fn question ->
            build_question_with_answer_and_solution_if_ungraded(%{
              question: question,
              assessment: assessment
            })
          end)
      }
    )
  end

  defp build_library(%{library: library}) do
    transform_map_for_view(library, %{
      chapter: :chapter,
      globals: :globals,
      external: &build_external_library(%{external_library: &1.external})
    })
  end

  def build_question(%{question: question}) do
    Map.merge(
      build_generic_question_fields(%{question: question}),
      build_question_content_by_type(%{question: question})
    )
  end

  defp build_external_library(%{external_library: external_library}) do
    transform_map_for_view(external_library, [:name, :symbols])
  end

  defp build_question_with_answer_and_solution_if_ungraded(%{
         question: question,
         assessment: assessment
       }) do
    components = [
      build_question(%{question: question}),
      build_answer_fields_by_question_type(%{question: question}),
      build_solution_if_ungraded_by_type(%{question: question, assessment: assessment})
    ]

    components
    |> Enum.filter(& &1)
    |> Enum.reduce(%{}, &Map.merge/2)
  end

  defp build_generic_question_fields(%{question: question}) do
    transform_map_for_view(question, %{
      id: :id,
      type: :type,
      library: &build_library(%{library: &1.library}),
      maxXp: :max_xp,
      maxGrade: :max_grade
    })
  end

  defp build_solution_if_ungraded_by_type(%{
         question: %{question: question, type: question_type},
         assessment: %{type: assessment_type}
       }) do
    if assessment_type not in @graded_assessment_types do
      solution_getter =
        case question_type do
          :programming -> &Map.get(&1, "solution")
          :mcq -> &find_correct_choice(&1["choices"])
        end

      transform_map_for_view(question, %{solution: solution_getter})
    end
  end

  defp answer_builder_for(:programming), do: & &1.answer["code"]
  defp answer_builder_for(:mcq), do: & &1.answer["choice_id"]

  defp build_answer_fields_by_question_type(%{
         question: %{answer: answer, type: question_type}
       }) do
    # No need to check if answer exists since empty answer would be a
    # `%Answer{..., answer: nil}` and nil["anything"] = nil

    %{grader: grader} = answer

    transform_map_for_view(answer, %{
      answer: answer_builder_for(question_type),
      comment: :comment,
      grader: grader_builder(grader),
      gradedAt: graded_at_builder(grader),
      xp: &((&1.xp || 0) + (&1.xp_adjustment || 0)),
      grade: &((&1.grade || 0) + (&1.adjustment || 0)),
      autogradingStatus: :autograding_status,
      autogradingResults: build_results(%{results: answer.autograding_results})
    })
  end

  defp build_results(%{results: results}) do
    case results do
      nil -> nil
      _ -> &Enum.map(&1.autograding_results, fn result -> build_result(result) end)
    end
  end

  def build_result(result) do
    transform_map_for_view(result, %{
      resultType: "resultType",
      expected: "expected",
      actual: "actual",
      errorType: "errorType",
      errors: build_errors(result["errors"])
    })
  end

  defp build_errors(errors) do
    case errors do
      nil -> nil
      _ -> &Enum.map(&1["errors"], fn error -> build_error(error) end)
    end
  end

  defp build_error(error) do
    transform_map_for_view(error, %{
      errorType: "errorType",
      line: "line",
      location: "location",
      errorLine: "errorLine",
      errorExplanation: "errorExplanation"
    })
  end

  defp build_choice(choice) do
    transform_map_for_view(choice, %{
      id: "choice_id",
      content: "content",
      hint: "hint"
    })
  end

  defp build_testcase(testcase) do
    transform_map_for_view(testcase, %{
      answer: "answer",
      score: "score",
      program: "program"
    })
  end

  defp build_question_content_by_type(%{question: %{question: question, type: question_type}}) do
    case question_type do
      :programming ->
        transform_map_for_view(question, %{
          content: "content",
          prepend: "prepend",
          solutionTemplate: "template",
          postpend: "postpend",
          testcases: &Enum.map(&1["public"], fn testcase -> build_testcase(testcase) end)
        })

      :mcq ->
        transform_map_for_view(question, %{
          content: "content",
          choices: &Enum.map(&1["choices"], fn choice -> build_choice(choice) end)
        })
    end
  end

  defp find_correct_choice(choices) do
    choices
    |> Enum.find(&Map.get(&1, "is_correct"))
    |> Map.get("choice_id")
  end
end
