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
      student_ids = Enum.map(team_attrs, &Map.get(&1, "userId"))
      if student_already_in_team?(student_ids, assessment_id) do
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

  defp student_already_in_team?(student_ids, assessment_id) do
    # Check if any of the students in team_attrs are already in a team for the same assessment
    query =
      from tm in TeamMember,
        join: t in assoc(tm, :team),
        where: tm.student_id in ^student_ids and t.assessment_id == ^assessment_id,
        select: tm.student_id

    existing_student_ids = Repo.all(query)

    Enum.any?(student_ids, fn student_id -> Enum.member?(existing_student_ids, student_id) end)
  end


  def update_team(%Team{} = team, new_assessment_id, student_ids) do
    old_assessment_id = team.assessment_id
    team_id = team.id
    new_student_ids = Enum.map(hd(student_ids), fn student -> Map.get(student, "userId") end)
    if student_already_in_team?(new_student_ids, new_assessment_id) do
      {:error, {:conflict, "One or more students are already in another team for the same assessment!"}}
    else
      attrs = %{assessment_id: new_assessment_id}

      team
      |> cast(attrs, [:assessment_id])
      |> validate_required([:assessment_id])
      |> foreign_key_constraint(:assessment_id)
      |> Ecto.Changeset.change()
      |> Repo.update()
      |> case do
        {:ok, updated_team} ->
          if old_assessment_id != new_assessment_id do
            delete_associated_submission(team_id, old_assessment_id)
          end

          update_team_members(updated_team, student_ids, team_id)
          {:ok, updated_team}

        error ->
          error
      end
    end
  end

  defp update_team_members(team, student_ids, team_id) do
    current_student_ids = team.team_members |> Enum.map(&(&1.student_id))
    new_student_ids =  Enum.map(hd(student_ids), fn student -> Map.get(student, "userId") end)

    student_ids_to_add = Enum.filter(new_student_ids, fn elem -> not Enum.member?(current_student_ids, elem) end)
    student_ids_to_remove = Enum.filter(current_student_ids, fn elem -> not Enum.member?(new_student_ids, elem) end)

    Enum.each(student_ids_to_add, fn student_id ->
      %TeamMember{}
      |> Ecto.Changeset.change(%{team_id: team_id, student_id: student_id}) # Change here
      |> Repo.insert()
    end)

    Enum.each(student_ids_to_remove, fn student_id ->
      from(tm in TeamMember, where: tm.team_id == ^team_id and tm.student_id == ^student_id)
      |> Repo.delete_all()
    end)
  end

  defp delete_associated_submission(team_id, old_assessment_id) do
  end

  def delete_team(%Team{} = team) do
    team
    |> Repo.delete()
  end

  # def bulk_upload_teams(teams_params) do
  #   teams = Jason.decode!(teams_params)
  #   Enum.map(teams, fn team ->
  #     case get_by_assessment_id(team["assessment_id"]) do
  #       nil -> create_team(team)
  #       existing_team -> update_team(existing_team, team)
  #     end
  #   end)
  # end

  # def get_by_assessment_id(assessment_id) do
  #   from(Team)
  #   |> where(assessment_id: ^assessment_id)
  #   |> Repo.one()
  # end
end
