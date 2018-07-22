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
      grade: submission.grade,
      submissionId: submission.id,
      student: %{
        name: submission.student.name,
        id: submission.student.id
      },
      assessment: %{
        type: submission.assessment.type,
        max_grade: submission.assessment.max_grade,
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
      max_grade: answer.question.max_grade,
      grade: %{
        grade: answer.grade,
        adjustment: answer.adjustment,
        comment: answer.comment
      }
    }
  end
end
