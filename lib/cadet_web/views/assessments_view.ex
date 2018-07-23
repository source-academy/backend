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
      attempted: :attempted,
      maximumEXP: :max_xp,
      coverImage: &Cadet.Assessments.Image.url({&1.cover_picture, &1})
    })
  end

  def render("show.json", %{assessment: assessment}) do
    transform_map_for_view(
      assessment,
      %{
        id: :id,
        title: :title,
        type: :type,
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

  def build_library(%{library: library}) do
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
    transform_map_for_view(external_library, %{
      name: :name,
      exposedSymbols: :exposed_symbols
    })
  end

  defp build_question_with_answer_and_solution_if_ungraded(%{
         question: question,
         assessment: assessment
       }) do
    components = [
      build_question(%{question: question}),
      build_answer_by_question_type(%{question: question}),
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
      library: &build_library(%{library: &1.library})
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

  defp build_answer_by_question_type(%{question: %{answer: answer, type: question_type}}) do
    # No need to check if answer exists since empty answer would be a
    # `%Answer{..., answer: nil}` and nil["anything"] = nil

    answer_getter =
      case question_type do
        :programming -> & &1.answer["code"]
        :mcq -> & &1.answer["choice_id"]
      end

    transform_map_for_view(answer, %{answer: answer_getter})
  end

  def build_choice(%{choice: choice}) do
    transform_map_for_view(choice, %{
      id: "choice_id",
      content: "content",
      hint: "hint"
    })
  end

  defp build_question_content_by_type(%{question: %{question: question, type: question_type}}) do
    case question_type do
      :programming ->
        transform_map_for_view(question, %{
          content: "content",
          solutionTemplate: "solution_template",
          solutionHeader: "solution_header"
        })

      :mcq ->
        transform_map_for_view(question, %{
          content: "content",
          choices: &Enum.map(&1["choices"], fn choice -> build_choice(%{choice: choice}) end)
        })
    end
  end

  defp find_correct_choice(choices) do
    choices
    |> Enum.find(&Map.get(&1, "is_correct"))
    |> Map.get("choice_id")
  end
end
