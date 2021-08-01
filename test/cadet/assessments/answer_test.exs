defmodule Cadet.Assessments.AnswerTest do
  alias Cadet.Assessments.Answer

  use Cadet.ChangesetCase, entity: Answer

  @required_fields ~w(answer submission_id question_id type)a

  setup do
    assessment = insert(:assessment, %{is_published: true})
    student = insert(:course_registration, %{role: :student})
    submission = insert(:submission, %{student: student, assessment: assessment})
    mcq_question = insert(:mcq_question, %{assessment: assessment})
    programming_question = insert(:programming_question, %{assessment: assessment})

    valid_mcq_params = %{
      submission_id: submission.id,
      question_id: mcq_question.id,
      type: mcq_question.type,
      answer: %{choice_id: 0},
      grade: 1
    }

    valid_programming_params = %{
      submission_id: submission.id,
      question_id: programming_question.id,
      type: programming_question.type,
      answer: %{code: "hello world"},
      grade: 1
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

  describe "changeset" do
    test "valid mcq question params", %{valid_mcq_params: params} do
      assert_changeset_db(params, :valid)
    end

    test "valid programming question with id params", %{valid_programming_params: params} do
      assert_changeset_db(params, :valid)
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

      assert_changeset(params, :valid)
    end

    test "converts valid mcq params with string value to integer", %{valid_mcq_params: params} do
      string_params = Map.put(params, :answer, %{choice_id: "0"})

      answer =
        %Answer{}
        |> Answer.changeset(string_params)
        |> Repo.insert!()

      assert is_integer(answer.answer.choice_id)
    end

    test "invalid changeset mcq question wrong answer format", %{valid_mcq_params: params} do
      params_wrong_type = Map.put(params, :answer, %{choice_id: "hello world"})
      assert_changeset(params_wrong_type, :invalid)

      params_wrong_field = Map.put(params, :answer, %{code: 2})
      assert_changeset(params_wrong_field, :invalid)
    end

    test "invalid changeset programming question wrong answer format", %{
      valid_programming_params: params
    } do
      params_wrong_type = Map.put(params, :answer, %{choice_id: "hello world"})
      assert_changeset(params_wrong_type, :invalid)

      params_wrong_field = Map.put(params, :answer, %{code: 2})
      assert_changeset(params_wrong_field, :invalid)
    end

    test "invalid changeset missing required params", %{valid_mcq_params: params} do
      for field <- @required_fields do
        params_missing_field = Map.delete(params, field)

        assert_changeset(params_missing_field, :invalid)
      end
    end

    test "invalid changeset foreign key constraints",
         %{
           valid_mcq_params: params,
           mcq_question: mcq_question,
           assessment: assessment,
           submission: submission
         } do
      {:ok, _} = Repo.delete(mcq_question)

      assert_changeset_db(params, :invalid)

      new_mcq_question = insert(:mcq_question, %{assessment: assessment})
      {:ok, _} = Repo.delete(submission)

      params
      |> Map.put(:question_id, new_mcq_question.id)
      |> assert_changeset_db(:invalid)
    end

    test "invalid changeset without question_id" do
      assert_changeset(%{}, :invalid, :grading_changeset)
    end
  end
end
