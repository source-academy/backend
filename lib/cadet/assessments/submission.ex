defmodule Cadet.Assessments.Submission do
  @moduledoc false
  use Cadet, :model

  alias Cadet.Accounts.User
  alias Cadet.Assessments.Assessment
  alias Cadet.Assessments.Answer

  schema "submissions" do
    field(:xp, :integer, virtual: true)

    belongs_to(:assessment, Assessment)
    belongs_to(:student, User)
    has_many(:answers, Answer)

    timestamps()
  end

  def changeset(submission, params) do
    submission
    |> cast(params, [])
    |> validate_role(:student, :student)
  end

  def validate_role(changeset, user, role) do
    validate_change(changeset, user, fn ^user, user ->
      if user.role == role, do: [], else: [{user, "does not have the role #{role}"}]
    end)
  end
end
