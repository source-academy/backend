defmodule Cadet.Accounts.Team do
  use Cadet, :model

  alias Cadet.Accounts.TeamMember
  alias Cadet.Assessments.{Assessment, Submission}

  schema "teams" do

    belongs_to(:assessment, Assessment)
    has_one(:submission, Submission, on_delete: :delete_all)
    has_many(:team_members, TeamMember, on_delete: :delete_all)

    timestamps()
  end

  @required_fields ~w(assessment_id)a

  def changeset(team, attrs) do
    team
    |> cast(attrs, @required_fields)
    |> validate_required(@required_fields)
    |> foreign_key_constraint(:assessment_id)
  end
end
