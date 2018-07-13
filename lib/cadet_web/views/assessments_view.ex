defmodule CadetWeb.AssessmentsView do
  use CadetWeb, :view

  @graded_assessment_types ~w(mission sidequest contest)a

  def render("index.json", %{assessments: assessments}) do
    render_many(assessments, CadetWeb.AssessmentsView, "overview.json", as: :assessment)
  end

  def render("overview.json", %{assessment: assessment}) do
    %{
      id: assessment.id,
      title: assessment.title,
      shortSummary: assessment.summary_short,
      openAt: DateTime.to_string(assessment.open_at),
      closeAt: DateTime.to_string(assessment.close_at),
      type: assessment.type,
      maximumEXP: assessment.max_xp,
      coverImage: Cadet.Assessments.Image.url({assessment.cover_picture, assessment})
    }
  end

  def render("show.json", %{assessment: assessment}) do
    %{
      id: assessment.id,
      title: assessment.title,
      type: assessment.type,
      longSummary: assessment.summary_long,
      missionPDF: Cadet.Assessments.Upload.url({assessment.mission_pdf, assessment}),
      questions:
        render_many(
          assessment.questions,
          CadetWeb.AssessmentsView,
          "question.json",
          %{as: :question, is_graded: assessment.type in @graded_assessment_types}
        )
    }
  end

  def render("question.json", params = %{question: question}) do
    %{
      id: question.id,
      type: question.type,
      library:
        render_one(question.library, CadetWeb.AssessmentsView, "library.json", as: :library)
    }
    |> add_question_fields_by_type(params)
  end

  def render("library.json", %{library: library}) do
    fields = [:globals, :files, :externals, :chapter]
    Map.take(library, fields)
  end

  defp add_question_fields_by_type(partial, params = %{question: question}) do
    case question.type do
      :programming -> add_programming_question_fields(partial, params)
      :multiple_choice -> add_mcq_question_fields(partial, params)
    end
  end

  defp add_programming_question_fields(
         partial,
         params = %{question: %{question: programming_question, answer: answer}}
       ) do
    programming_fields = %{
      content: programming_question["content"],
      solutionTemplate: programming_question["solution_template"],
      solutionHeader: programming_question["solution_header"],
      answer: answer && answer.answer["code"]
    }

    case params.is_graded do
      true -> Map.merge(partial, programming_fields)
      false -> Map.merge(partial, programming_fields)
    end
  end

  defp add_mcq_question_fields(
         partial,
         params = %{question: %{question: mcq_question, answer: answer}}
       ) do
    mcq_fields = %{
      content: mcq_question["content"],
      choices:
        render_many(
          mcq_question["choices"],
          CadetWeb.AssessmentsView,
          "mcq_choice.json",
          as: :mcq_choice
        ),
      answer: answer && answer.answer["choice_id"]
    }

    case params.is_graded do
      true -> Map.merge(partial, mcq_fields)
      false -> Map.merge(partial, mcq_fields)
    end
  end

  def render("mcq_choice.json", %{mcq_choice: choice}) do
    %{
      id: choice["choice_id"],
      content: choice["content"],
      hint: choice["hint"]
    }
  end
end
