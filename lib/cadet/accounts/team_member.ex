defmodule Cadet.Accounts.TeamMember do
  @moduledoc """
  This module defines the Ecto schema and changeset for team members in the Cadet.Accounts context.
  Team members represent the association between a student and a team within a course.
  """

  use Ecto.Schema

  import Ecto.Changeset

  alias Cadet.Accounts.{CourseRegistration, Team}

  @doc """
  Ecto schema definition for team members.
  This schema represents the relationship between a student and a team within a course.
  Fields:
    - `student`: A reference to the student's course registration.
    - `team`: A reference to the team associated with the student.
  """
  schema "team_members" do
    belongs_to(:student, CourseRegistration)
    belongs_to(:team, Team)

    timestamps()
  end

  @required_fields ~w(student_id team_id)a

  @doc """
  Builds an Ecto changeset for a team member.
  This function is used to create or update a team member record based on the provided attributes.
  Args:
    - `team_member`: The existing team member struct.
    - `attrs`: The attributes to be cast and validated for the changeset.
  Returns:
    A changeset struct with cast and validated attributes.
  """
  def changeset(team_member, attrs) do
    team_member
    |> cast(attrs, @required_fields)
    |> validate_required(@required_fields)
    |> foreign_key_constraint(:team_id)
    |> foreign_key_constraint(:student_id)
  end
end
