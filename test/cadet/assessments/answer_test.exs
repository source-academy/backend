defmodule Cadet.Assessments.AnswerTest do
  use Cadet.DataCase

  alias Cadet.Assessments.Answer

  describe "Changesets" do
    setup do
      assessment = insert(:assessment, %{is_published: true})
      student = insert(:user, %{role: :student})
      submission = insert(:submission, %{student: student, assessment: assessment})
      mcq_question = insert(:question, %{assessment: assessment, type: :multiple_choice})
      programming_question = insert(:question, %{assessment: assessment, type: :programming})

      {:ok,
       [
         assessment: assessment,
         mcq_question: mcq_question,
         programming_question: programming_question,
         student: student,
         submission: submission
       ]}
    end

    test "valid mcq question with model params", context do
      %{assessment: assessment, submission: submission, mcq_question: question} = context

      params = %{
        submission: submission,
        question: question,
        type: question.type,
        answer: %{choice_id: 0},
        xp: 1
      }

      changeset = Answer.changeset(%Answer{}, params)
      assert(changeset.valid?, Kernel.inspect(params))
    end

    test "valid mcq question with id params", context do
      %{assessment: assessment, submission: submission, mcq_question: question} = context

      params = %{
        submission_id: submission.id,
        question_id: question.id,
        type: question.type,
        answer: %{choice_id: 0},
        xp: 1
      }

      changeset = Answer.changeset(%Answer{}, params)
      assert(changeset.valid?, Kernel.inspect(params))
    end

    test "valid programming question with model params", context do
      %{assessment: assessment, submission: submission, programming_question: question} = context

      params = %{
        submission: submission,
        question: question,
        type: question.type,
        answer: %{code: "hello world"},
        xp: 1
      }

      changeset = Answer.changeset(%Answer{}, params)
      assert(changeset.valid?, Kernel.inspect(params))
    end

    test "valid programming question with id params", context do
      %{assessment: assessment, submission: submission, programming_question: question} = context

      params = %{
        submission_id: submission.id,
        question_id: question.id,
        type: question.type,
        answer: %{code: "hello world"},
        xp: 1
      }

      changeset = Answer.changeset(%Answer{}, params)
      assert(changeset.valid?, Kernel.inspect(params))
    end
  end
end
