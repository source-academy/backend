defmodule Cadet.Assessments.SubmissionVotes do
  @moduledoc false
  use Cadet, :model

  alias Cadet.Accounts.User
  alias Cadet.Assessments.{Question, Submission}

  schema "submission_votes" do
    field(:score, :integer)

    belongs_to(:user, User)
    belongs_to(:submission, Submission)
    belongs_to(:question, Question)
    timestamps()
  end

  @required_fields ~w(user_id submission_id question_id)a
  @optional_fields ~w(score)a

  def changeset(submission_vote, params) do
    submission_vote
    |> cast(params, @required_fields ++ @optional_fields)
    |> add_belongs_to_id_from_model([:user, :submission, :question], params)
    |> validate_required(@required_fields)
    |> foreign_key_constraint(:user_id)
    |> foreign_key_constraint(:submission_id)
    |> foreign_key_constraint(:question_id)
  end
end
