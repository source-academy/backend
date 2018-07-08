defmodule Cadet.Assessments.AnswerTest do
  use Cadet.DataCase

  alias Cadet.Assessments.Answer

  @required_fields ~w(answer submission_id question_id type)a

  setup do
    assessment = insert(:assessment, %{is_published: true})
    student = insert(:user, %{role: :student})
    submission = insert(:submission, %{student: student, assessment: assessment})
    mcq_question = insert(:question, %{assessment: assessment, type: :multiple_choice})
    programming_question = insert(:question, %{assessment: assessment, type: :programming})

    valid_mcq_params = %{
      submission_id: submission.id,
      question_id: mcq_question.id,
      type: mcq_question.type,
      answer: %{choice_id: 0},
      xp: 1
    }

    valid_programming_params = %{
      submission_id: submission.id,
      question_id: programming_question.id,
      type: programming_question.type,
      answer: %{code: "hello world"},
      xp: 1
    }

    {:ok,
     %{
       assessment: assessment,
       mcq_question: mcq_question,
       valid_mcq_params: valid_mcq_params,
       programming_question: programming_question,
       valid_programming_params: valid_programming_params,
       student: student,
       submission: submission
     }}
  end

  describe "Changesets" do
    test "valid mcq question params", %{valid_mcq_params: params} do
      result =
        %Answer{}
        |> Answer.changeset(params)
        |> Repo.insert()

      assert({:ok, _} = result, inspect(result))
    end

    test "valid programming question with id params", %{valid_programming_params: params} do
      result =
        %Answer{}
        |> Answer.changeset(params)
        |> Repo.insert()

      assert({:ok, _} = result, inspect(result))
    end

    test "converts valid params with models into ids",
         %{
           submission: submission,
           programming_question: question,
           valid_programming_params: params
         } do
      params =
        params
        |> Map.delete(:submission_id)
        |> Map.delete(:question_id)
        |> Map.delete(:type)
        |> Map.put(:submission, submission)
        |> Map.put(:question, question)

      changeset = Answer.changeset(%Answer{}, params)
      assert(changeset.valid?, Kernel.inspect(params))
    end

    test "invalid changeset mcq question wrong answer format", %{valid_mcq_params: params} do
      params_wrong_type = Map.put(params, :answer, %{choice_id: "hello world"})
      refute(Answer.changeset(%Answer{}, params_wrong_type).valid?, inspect(params_wrong_type))

      params_wrong_field = Map.put(params, :answer, %{code: 2})
      refute(Answer.changeset(%Answer{}, params_wrong_field).valid?, inspect(params_wrong_field))
    end

    test "invalid changeset programming question wrong answer format", %{
      valid_programming_params: params
    } do
      params_wrong_type = Map.put(params, :answer, %{choice_id: "hello world"})
      refute(Answer.changeset(%Answer{}, params_wrong_type).valid?, inspect(params_wrong_type))

      params_wrong_field = Map.put(params, :answer, %{code: 2})
      refute(Answer.changeset(%Answer{}, params_wrong_field).valid?, inspect(params_wrong_field))
    end

    test "invalid changeset missing required params", %{valid_mcq_params: params} do
      Enum.each(@required_fields, fn field ->
        params_missing_field = Map.delete(params, field)

        refute(
          Answer.changeset(%Answer{}, params_missing_field).valid?,
          inspect(params_missing_field)
        )
      end)
    end

    test "invalid changeset foreign key constraints",
         %{
           valid_mcq_params: params,
           mcq_question: mcq_question,
           assessment: assessment,
           submission: submission
         } do
      {:ok, _} = Repo.delete(mcq_question)

      result =
        %Answer{}
        |> Answer.changeset(params)
        |> Repo.insert()

      assert({:error, _} = result, inspect(result))

      new_mcq_question = insert(:question, %{assessment: assessment, type: :multiple_choice})
      {:ok, _} = Repo.delete(submission)

      result =
        %Answer{}
        |> Answer.changeset(Map.put(params, :question_id, new_mcq_question.id))
        |> Repo.insert()

      assert({:error, _} = result, inspect(result))
    end
  end
end
