defmodule Cadet.Autograder.Utilities do
  @moduledoc """
  This module defines functions that support the autograder functionality.
  """
  use Cadet, :context

  import Ecto.Query
  import Cadet.Factory

  alias Ecto.Multi

  alias Cadet.Accounts.User
  alias Cadet.Assessments.{Answer, Assessment, Question, Submission}

  @batch_size 500

  def process do
    for assessment <- fetch_assessment_past_close_at(),
        %{student_id: student_id, submission: submission} <- fetch_submissions(assessment.id) do
      if submission do
        dispatch_submission(submission)
      else
        build_empty_submission(%{student_id: student_id, assessment: assessment})
      end
    end
  end

  def dispatch_submission(submission = %Submission{}) do
  end

  def build_empty_submission(%{student_id: student_id, assessment: assessment}) do
    submission =
      %Submission{}
      |> Submission.changeset(%{
        student_id: student_id,
        assessment: assessment,
        status: :submitted
      })
      |> Repo.insert!()

    assessment.questions
    |> Enum.filter(fn qn -> qn.type == :programming end)
    |> Enum.reduce(
      Multi.new(),
      fn qn, multi ->
        Multi.insert(
          multi,
          "question#{qn.id}",
          %Answer{}
          |> Answer.changeset(%{
            answer: %{code: "Question not answered by student."},
            question_id: qn.id,
            submission_id: submission.id,
            type: qn.type
          })
          |> Answer.autograding_changeset(%{grade: 0, autograding_status: :success})
        )
      end
    )
    |> Repo.transaction()
  end

  def fetch_submissions(assessment_id) when is_ecto_id(assessment_id) do
    User
    |> where(role: "student")
    |> join(:left, [u], s in Submission, u.id == s.student_id)
    |> select([u, s], %{student_id: u.id, submission: s})
    |> Repo.all()
  end

  def fetch_assessment_past_close_at do
    Assessment
    |> where(is_published: true)
    |> where([a], a.close_at < ^Timex.now() and a.close_at >= ^Timex.shift(Timex.now(), days: -1))
    |> where([a], a.type == "mission")
    |> join(:inner, [a], q in assoc(a, :questions))
    |> preload([_, q], questions: q)
    |> Repo.all()
  end

  def seed_assessments do
    assessments =
      Enum.map(1..3, fn _ ->
        insert(:assessment, %{
          is_published: true,
          open_at: Timex.shift(Timex.now(), days: -5),
          close_at: Timex.shift(Timex.now(), hours: -4),
          type: :mission
        })
      end)

    Enum.map(assessments, &insert_list(3, :programming_question, %{assessment: &1}))
  end
end
