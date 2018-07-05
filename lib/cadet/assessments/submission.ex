defmodule Cadet.Assessments.Submission do
  @moduledoc false
  use Cadet, :model

  import Ecto.Query

  alias Cadet.Assessments.SubmissionStatus
  alias Cadet.Accounts.User
  alias Cadet.Assessments.Assessment
  alias Cadet.Assessments.Answer

  # TODO: Add unique indices

  schema "submissions" do
    field(:status, SubmissionStatus, default: :attempting)
    field(:submitted_at, Timex.Ecto.DateTime)
    field(:override_xp, :integer)

    belongs_to(:assessment, Assessment)
    belongs_to(:student, User)
    belongs_to(:grader, User)
    has_many(:answers, Answer)

    timestamps()
  end

  @required_fields ~w(status student_id assessment_id)a
  @optional_fields ~w(override_xp submitted_at)a

  def changeset(submission, params) do
    params = convert_date(params, :submitted_at)

    submission
    |> cast(params, @required_fields ++ @optional_fields)
    |> add_belongs_to_id_from_model(:student, params)
    |> add_belongs_to_id_from_model(:assessment, params)
    |> validate_required(@required_fields)
    |> foreign_key_constraint(:student)
    |> foreign_key_constraint(:assessment)
    # TODO: change back to student for deployment
    |> validate_role(:student, :staff)
    |> validate_role(:grader, :staff)
  end

  def validate_role(changeset, assoc, role) do
    # TODO: update to accept named list, do joins +reduce for performance
    changeset
    |> Map.get(:changes)
    |> Map.get(String.to_atom("#{assoc}_id"))
    |> case do
      nil ->
        changeset

      changeset_field ->
        assoc_reflection = __schema__(:association, assoc)

        user =
          assoc_reflection
          |> Map.get(:queryable)
          |> where([user], user.id == ^changeset_field)
          |> Repo.one()

        if user.role == role do
          changeset
        else
          add_error(changeset, assoc, "Does not have the role #{role}")
        end
    end
  end
end
