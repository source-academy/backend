defmodule Cadet.Assessments.SubmissionVotes do
  @moduledoc false
  use Cadet, :model

  alias Cadet.Accounts.CourseRegistration
  alias Cadet.Assessments.{Question, Submission}

  schema "submission_votes" do
    field(:score, :integer)

    belongs_to(:voter, CourseRegistration)
    belongs_to(:submission, Submission)
    belongs_to(:question, Question)
    timestamps()
  end

  @required_fields ~w(voter_id submission_id question_id)a
  @optional_fields ~w(score)a

  # There is no unique constraint for contest vote scores.
  def changeset(submission_vote, params) do
    submission_vote
    |> cast(params, @required_fields ++ @optional_fields)
    |> add_belongs_to_id_from_model([:voter, :submission, :question], params)
    |> validate_required(@required_fields)
    |> foreign_key_constraint(:voter_id)
    |> foreign_key_constraint(:submission_id)
    |> foreign_key_constraint(:question_id)
  end
end
