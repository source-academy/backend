defmodule Cadet.Assessments.SubmissionVotesTest do
  alias Cadet.Assessments.SubmissionVotes

  use Cadet.ChangesetCase, entity: SubmissionVotes

  @required_fields ~w(user_id submission_id question_id)a

  setup do
    question = insert(:question)
    user = insert(:user)
    submission = insert(:submission)

    valid_params = %{user_id: user.id, submission_id: submission.id, question_id: question.id}

    {:ok, %{question: question, user: user, submission: submission, valid_params: valid_params}}
  end

  describe "Changesets" do
    test "valid params", %{valid_params: params} do
      assert_changeset_db(params, :valid)
    end

    test "converts valid params with models into ids", %{
      question: question,
      user: user,
      submission: submission
    } do
      assert_changeset_db(%{question: question, user: user, submission: submission}, :valid)
    end

    test "invalid changeset missing params", %{valid_params: params} do
      for field <- @required_fields do
        params_missing_field = Map.delete(params, field)

        assert_changeset(params_missing_field, :invalid)
      end
    end

    test "invalid changeset foreign key constraint", %{
      question: question,
      user: user,
      submission: submission,
      valid_params: params
    } do
      {:ok, _} = Repo.delete(user)

      assert_changeset_db(params, :invalid)

      new_user = insert(:user)
      {:ok, _} = Repo.delete(question)

      params
      |> Map.put(:user_id, new_user.id)
      |> assert_changeset_db(:invalid)

      new_question = insert(:question)
      {:ok, _} = Repo.delete(submission)

      params
      |> Map.put(:question_id, new_question.id)
      |> assert_changeset_db(:invalid)
    end

    test "invalid changeset unique constraint", %{
      valid_params: params
    } do
      params = Map.put(params, :score, 2)
      first_entry = SubmissionVotes.changeset(%SubmissionVotes{}, params)
      {:ok, _} = Repo.insert(first_entry)
      new_submission = insert(:submission)

      second_entry = %{
        user_id: params.user_id,
        submission_id: new_submission.id,
        question_id: params.question_id,
        score: params.score
      }

      changeset = SubmissionVotes.changeset(%SubmissionVotes{}, second_entry)
      {:error, changeset} = Repo.insert(changeset)
      refute changeset.valid?
    end
  end
end
