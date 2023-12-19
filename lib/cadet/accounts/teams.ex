defmodule Cadet.Accounts.Teams do
  @moduledoc """
  This module provides functions to manage teams in the Cadet system.
  """

  use Cadet, [:context, :display]
  use Ecto.Schema
  
  import Ecto.Changeset
  import Ecto.Query

  alias Cadet.Repo
  alias Cadet.Accounts.{Team, TeamMember, CourseRegistration}
  alias Cadet.Assessments.{Answer, Assessment, Submission}

  @doc """
  Creates a new team and assigns an assessment and team members to it.

  ## Parameters

    * `attrs` - A map containing the attributes for assessment id and creating the team and its members.

  ## Returns

  Returns a tuple `{:ok, team}` on success; otherwise, an error tuple.

  """
  def create_team(attrs) do
    assessment_id = attrs["assessment_id"]
    teams = attrs["student_ids"]
    assessment = Cadet.Repo.get(Cadet.Assessments.Assessment, assessment_id)

    cond do
      !all_team_within_max_size(teams, assessment.max_team_size) ->
        {:error, {:conflict, "One or more teams exceed the maximum team size!"}}
       
      !all_students_distinct(teams) ->
        {:error, {:conflict, "One or more students appear multiple times in a team!"}}
      
      student_already_assigned(teams, assessment_id) ->
        {:error, {:conflict, "One or more students already in a team for this assessment!"}}

      true -> 
        Enum.reduce_while(attrs["student_ids"], {:ok, nil}, fn team_attrs, {:ok, _} ->
          student_ids = Enum.map(team_attrs, &Map.get(&1, "userId"))
          IO.inspect(student_ids)
          {:ok, team} = %Team{}
                      |> Team.changeset(attrs)
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
        end)
    end
  end

  @doc """
  Validates whether there are student(s) who are already assigned to another group.

  ## Parameters

    * `team_attrs` - A list of all the teams and their members.
    * `assessment_id` - Id of the target assessment.

  ## Returns

  Returns `true` on success; otherwise, `false`.

  """
  defp student_already_assigned(team_attrs, assessment_id) do
    Enum.all?(team_attrs, fn team ->
      ids = Enum.map(team, &Map.get(&1, "userId"))

      unique_ids_count = ids |> Enum.uniq() |> Enum.count()
      all_ids_distinct = unique_ids_count == Enum.count(ids)

      student_already_in_team?(-1, ids, assessment_id)
    end)
  end

  defp all_students_distinct(team_attrs) do
    all_ids = team_attrs
      |> Enum.flat_map(fn team ->
        Enum.map(team, fn row -> Map.get(row, "userId") end)
      end)
  
    all_ids_count = all_ids |> Enum.uniq() |> Enum.count()
    all_ids_distinct = all_ids_count == Enum.count(all_ids)

    all_ids_distinct
  end

  defp all_team_within_max_size(teams, max_team_size) do 
    Enum.all?(teams, fn team ->
      ids = Enum.map(team, &Map.get(&1, "userId"))
      length(ids) <= max_team_size
    end)
  end

  @doc """
  Checks if one or more students are already in another team for the same assessment.

  ## Parameters

    * `team_id` - ID of the team being updated (use -1 for team creation)
    * `student_ids` - List of student IDs
    * `assessment_id` - ID of the assessment

  ## Returns

  Returns `true` if any student in the list is already a member of another team for the same assessment; otherwise, returns `false`.

  """
  defp student_already_in_team?(team_id, student_ids, assessment_id) do
    query =
      from tm in TeamMember,
        join: t in assoc(tm, :team),
        where: tm.student_id in ^student_ids and t.assessment_id == ^assessment_id and t.id != ^team_id,
        select: tm.student_id

    existing_student_ids = Repo.all(query)

    Enum.any?(student_ids, fn student_id -> Enum.member?(existing_student_ids, student_id) end)
  end

  @doc """
  Updates an existing team, the corresponding assessment, and its members.

  ## Parameters

    * `team` - The existing team to be updated
    * `new_assessment_id` - The ID of the updated assessment
    * `student_ids` - List of student ids for team members

  ## Returns

  Returns a tuple `{:ok, updated_team}` on success, containing the updated team details; otherwise, an error tuple.

  """
  def update_team(%Team{} = team, new_assessment_id, student_ids) do
    old_assessment_id = team.assessment_id
    team_id = team.id
    new_student_ids = Enum.map(hd(student_ids), fn student -> Map.get(student, "userId") end)
    if student_already_in_team?(team_id, new_student_ids, new_assessment_id) do
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

          update_team_members(updated_team, student_ids, team_id)
          {:ok, updated_team}

        error ->
          error
      end
    end
  end

  @doc """
  Updates team members based on the new list of student IDs.

  ## Parameters

    * `team` - The team being updated
    * `student_ids` - List of student ids for team members
    * `team_id` - ID of the team

  """
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

  @doc """
  Deletes a team along with its associated submissions and answers.

  ## Parameters

    * `team` - The team to be deleted

  """
  def delete_team(%Team{} = team) do
    Submission
    |> where(team_id: ^team.id)
    |> Repo.all()
    |> Enum.each(fn x ->
      Answer
      |> where(submission_id: ^x.id)
      |> Repo.delete_all()
    end)
    team
    |> Repo.delete()
  end
end
