defmodule Cadet.Assessments.SubmissionVotesTest do
  alias Cadet.Assessments.SubmissionVotes

  use Cadet.ChangesetCase, entity: SubmissionVotes

  @required_fields ~w(voter_id submission_id question_id)a

  setup do
    question = insert(:question)
    voter = insert(:course_registration)
    submission = insert(:submission)

    valid_params = %{voter_id: voter.id, submission_id: submission.id, question_id: question.id}

    {:ok, %{question: question, voter: voter, submission: submission, valid_params: valid_params}}
  end

  describe "Changesets" do
    test "valid params", %{valid_params: params} do
      assert_changeset_db(params, :valid)
    end

    test "converts valid params with models into ids", %{
      question: question,
      voter: voter,
      submission: submission
    } do
      assert_changeset_db(%{question: question, voter: voter, submission: submission}, :valid)
    end

    test "invalid changeset missing params", %{valid_params: params} do
      for field <- @required_fields do
        params_missing_field = Map.delete(params, field)

        assert_changeset(params_missing_field, :invalid)
      end
    end

    test "invalid changeset foreign key constraint", %{
      question: question,
      voter: voter,
      submission: submission,
      valid_params: params
    } do
      {:ok, _} = Repo.delete(voter)

      assert_changeset_db(params, :invalid)

      new_user = insert(:course_registration)
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

    # There is no constraint for unique vote score.
  end
end
