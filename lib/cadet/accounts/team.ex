defmodule Cadet.Accounts.Team do
  @moduledoc """
  This module defines the Ecto schema and changeset for teams in the Cadet.Accounts context.
  Teams represent groups of students collaborating on an assessment within a course.
  """

  use Cadet, :model

  alias Cadet.Accounts.TeamMember
  alias Cadet.Assessments.{Assessment, Submission}

  @doc """
  Ecto schema definition for teams.
  This schema represents a group of students collaborating on a specific assessment within a course.
  Fields:
    - `assessment`: A reference to the assessment associated with the team.
    - `submission`: A reference to the team's submission for the assessment.
    - `team_members`: A list of team members associated with the team.
  """
  schema "teams" do
    belongs_to(:assessment, Assessment)
    has_one(:submission, Submission, on_delete: :delete_all)
    has_many(:team_members, TeamMember, on_delete: :delete_all)

    timestamps()
  end

  @required_fields ~w(assessment_id)a

  @doc """
  Builds an Ecto changeset for a team.
  This function is used to create or update a team record based on the provided attributes.
  Args:
    - `team`: The existing team struct.
    - `attrs`: The attributes to be cast and validated for the changeset.
  Returns:
    A changeset struct with cast and validated attributes.
  """
  def changeset(team, attrs) do
    team
    |> cast(attrs, @required_fields)
    |> validate_required(@required_fields)
    |> foreign_key_constraint(:assessment_id)
  end
end
