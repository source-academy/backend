defmodule Cadet.Accounts.TeamMember do
  use Ecto.Schema
  import Ecto.Changeset

  alias Cadet.Accounts.CourseRegistration
  alias Cadet.Accounts.Team

  schema "team_members" do

    belongs_to(:student, CourseRegistration)
    belongs_to(:team, Team)

    timestamps()
  end

  @required_fields ~w(student_id team_id)a

  def changeset(team_member, attrs) do
    team_member
    |> cast(attrs, @required_fields)
    |> validate_required(@required_fields)
    |> foreign_key_constraint(:team_id)
    |> foreign_key_constraint(:student_id)
  end
end
