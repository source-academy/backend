defmodule Cadet.Accounts.Teams do

  use Cadet, [:context, :display]

  use Ecto.Schema
  import Ecto.Changeset
  import Ecto.Query
  alias Cadet.Repo
  alias Cadet.Accounts.{Team, TeamMember, CourseRegistration}
  alias Cadet.Assessments.Assessment

  def create_team(attrs) do
    assessment_id = attrs["assessment_id"]
    teams = attrs["student_ids"]

    Enum.reduce_while(teams, {:ok, nil}, fn team_attrs, {:ok, _} ->
      if student_already_in_team?(team_attrs, assessment_id) do
        {:halt, {:error, {:conflict, "Team with the same members already exists for this assessment!"}}}
      else
        {:ok, team} = %Team{}
                    |> cast(attrs, [:assessment_id])
                    |> validate_required([:assessment_id])
                    |> foreign_key_constraint(:assessment_id)
                    |> Repo.insert()
        team_id = team.id
        Enum.each(team_attrs, fn student ->
          student_id = Map.get(student, "userId")
          attributes = %{student_id: student_id, team_id: team_id}
          %TeamMember{}
          |> cast(attributes, [:student_id, :team_id])
          |> Repo.insert()
        end)
        {:cont, {:ok, team}}
      end
    end)
  end

  defp student_already_in_team?(team_attrs, assessment_id) do
    student_ids = Enum.map(team_attrs, &Map.get(&1, "userId"))

    # Check if any of the students in team_attrs are already in a team for the same assessment
    query =
      from tm in TeamMember,
        join: t in assoc(tm, :team),
        where: tm.student_id in ^student_ids and t.assessment_id == ^assessment_id,
        select: tm.student_id

    existing_student_ids = Repo.all(query)

    Enum.any?(student_ids, fn student_id -> Enum.member?(existing_student_ids, student_id) end)
  end


  def update_team(%Team{} = team, attrs) do
    assessment_id = attrs["assessment_id"]
    student_ids = attrs["student_ids"]

    team_id = team.id # Introduce a variable for team.id

    team
    |> cast(attrs, [:assessment_id])
    |> validate_required([:assessment_id])
    |> foreign_key_constraint(:assessment_id)
    |> Ecto.Changeset.change()
    |> Repo.update()
    |> case do
      {:ok, updated_team} ->
        update_team_members(updated_team, student_ids, team_id) # Pass team_id here
        {:ok, updated_team}

      error ->
        error
    end
  end

  defp update_team_members(team, student_ids, team_id) do # Add team_id parameter here
    current_student_ids = team.team_members |> Enum.map(&(&1.student_id))

    student_ids_to_add = Enum.difference(student_ids, current_student_ids)
    student_ids_to_remove = Enum.difference(current_student_ids, student_ids)

    Enum.each(student_ids_to_add, fn student_id ->
      %TeamMember{}
      |> Ecto.Changeset.change(team_id: team_id, student_id: student_id) # Use team_id here
      |> Repo.insert()
    end)

    Enum.each(student_ids_to_remove, fn student_id ->
      from(tm in TeamMember, where: tm.team_id == ^team_id and tm.student_id == ^student_id) # Remove ^ for student_id
      |> Repo.delete_all()
    end)
  end

  def delete_team(%Team{} = team) do
    team
    |> Repo.delete()
  end

  def bulk_upload_teams(teams_params) do
    teams = Jason.decode!(teams_params)
    Enum.map(teams, fn team ->
      case get_by_assessment_id(team["assessment_id"]) do
        nil -> create_team(team)
        existing_team -> update_team(existing_team, team)
      end
    end)
  end

  def get_by_assessment_id(assessment_id) do
    from(Team)
    |> where(assessment_id: ^assessment_id)
    |> Repo.one()
  end
end
