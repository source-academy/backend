defmodule CadetWeb.GradingView do
  use CadetWeb, :view

  def render("index.json", %{submissions: submissions}) do
    render_many(submissions, CadetWeb.GradingView, "submission.json", as: :submission)
  end

  def render("show.json", %{answers: answers}) do
    render_many(answers, CadetWeb.GradingView, "grading_info.json", as: :answer)
  end

  def render("submission.json", %{submission: submission}) do
    %{
      xp: submission.xp,
      submissionId: submission.id,
      student: %{
        name: submission.student.name,
        id: submission.student.id
      },
      assessment: %{
        type: submission.assessment.type,
        max_xp: submission.assessment.max_xp,
        id: submission.assessment.id
      }
    }
  end

  def render("grading_info.json", %{answer: answer}) do
    %{
      question: %{
        solution_template: answer.question.question["solution_template"],
        questionType: answer.question.type,
        questionId: answer.question.id,
        library: answer.question.library,
        content: answer.question.question["content"],
        answer: answer.answer["code"]
      },
      max_xp: answer.question.max_xp,
      grade: %{
        xp: answer.xp,
        adjustment: answer.adjustment,
        comment: answer.comment
      }
    }
  end
end
