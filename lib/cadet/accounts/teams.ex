defmodule Cadet.Accounts.Teams do
  @moduledoc """
  This module provides functions to manage teams in the Cadet system.
  """

  use Cadet, [:context, :display]
  use Ecto.Schema

  import Ecto.{Changeset, Query}
  require Logger

  alias Cadet.Repo
  alias Cadet.Accounts.{Team, TeamMember, Notification}
  alias Cadet.Assessments.{Answer, Submission}

  @doc """
  Returns all teams for a given course.

  ## Parameters

    * `course_id` - The ID of the course.

  ## Returns

  Returns a list of teams.

  """
  def all_teams_for_course(course_id) do
    Logger.info("Retrieving all teams for course #{course_id}")

    teams =
      Team
      |> join(:inner, [t], a in assoc(t, :assessment))
      |> where([t, a], a.course_id == ^course_id)
      |> Repo.all()
      |> Repo.preload(assessment: [:config], team_members: [student: [:user]])

    Logger.info("Retrieved #{length(teams)} teams for course #{course_id}")
    teams
  end

  @doc """
  Creates a new team and assigns an assessment and team members to it.

  ## Parameters

    * `attrs` - A map containing the attributes for assessment id and creating the team and its members.

  ## Returns

  Returns a tuple `{:ok, team}` on success; otherwise, an error tuple.

  """
  def create_team(attrs) do
    assessment_id = attrs["assessment_id"]
    Logger.info("Creating teams for assessment #{assessment_id}")

    teams = attrs["student_ids"]
    assessment = Cadet.Repo.get(Cadet.Assessments.Assessment, assessment_id)

    cond do
      !all_team_within_max_size?(teams, assessment.max_team_size) ->
        Logger.error(
          "Team creation failed for assessment #{assessment_id} - teams exceed maximum size"
        )

        {:error, {:conflict, "One or more teams exceed the maximum team size!"}}

      !all_students_distinct?(teams) ->
        Logger.error("Team creation failed for assessment #{assessment_id} - duplicate students")

        {:error, {:conflict, "One or more students appear multiple times in a team!"}}

      !all_student_enrolled_in_course?(teams, assessment.course_id) ->
        Logger.error(
          "Team creation failed for assessment #{assessment_id} - students not enrolled in course"
        )

        {:error, {:conflict, "One or more students not enrolled in this course!"}}

      student_already_assigned?(teams, assessment_id) ->
        Logger.error(
          "Team creation failed for assessment #{assessment_id} - students already assigned to teams"
        )

        {:error, {:conflict, "One or more students already in a team for this assessment!"}}

      true ->
        result =
          Enum.reduce_while(attrs["student_ids"], {:ok, nil}, fn team_attrs, {:ok, _} ->
            {:ok, team} =
              %Team{}
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

        Logger.info("Successfully created teams for assessment #{assessment_id}")
        result
    end
  end

  defp student_already_assigned?(team_attrs, assessment_id) do
    Enum.all?(team_attrs, fn team ->
      ids = Enum.map(team, &Map.get(&1, "userId"))

      student_already_in_team?(-1, ids, assessment_id)
    end)
  end

  defp all_students_distinct?(team_attrs) do
    all_ids =
      team_attrs
      |> Enum.flat_map(fn team ->
        Enum.map(team, fn row -> Map.get(row, "userId") end)
      end)

    all_ids_count = all_ids |> Enum.uniq() |> Enum.count()
    all_ids_distinct = all_ids_count == Enum.count(all_ids)

    all_ids_distinct
  end

  defp all_team_within_max_size?(teams, max_team_size) do
    Enum.all?(teams, fn team ->
      ids = Enum.map(team, &Map.get(&1, "userId"))
      length(ids) <= max_team_size
    end)
  end

  defp all_student_enrolled_in_course?(teams, course_id) do
    all_ids =
      teams
      |> Enum.flat_map(fn team ->
        Enum.map(team, fn row -> Map.get(row, "userId") end)
      end)

    query =
      from(cr in Cadet.Accounts.CourseRegistration,
        where: cr.id in ^all_ids and cr.course_id == ^course_id,
        select: count(cr.id)
      )

    count = Repo.one(query)
    count == length(all_ids)
  end

  # Checks if any of the given students are already in another team for the same
  # assessment. Pass team_id: -1 for team creation (matches no existing team).
  defp student_already_in_team?(team_id, student_ids, assessment_id) do
    query =
      from(tm in TeamMember,
        join: t in assoc(tm, :team),
        where:
          tm.student_id in ^student_ids and t.assessment_id == ^assessment_id and t.id != ^team_id,
        select: tm.student_id
      )

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
  def update_team(team = %Team{}, new_assessment_id, student_ids) do
    team_id = team.id
    new_student_ids = Enum.map(hd(student_ids), fn student -> Map.get(student, "userId") end)

    if student_already_in_team?(team_id, new_student_ids, new_assessment_id) do
      {:error,
       {:conflict, "One or more students are already in another team for the same assessment!"}}
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
      end
    end
  end

  defp update_team_members(team, student_ids, team_id) do
    current_student_ids = team.team_members |> Enum.map(& &1.student_id)
    new_student_ids = Enum.map(hd(student_ids), fn student -> Map.get(student, "userId") end)

    student_ids_to_add =
      Enum.filter(new_student_ids, fn elem -> not Enum.member?(current_student_ids, elem) end)

    student_ids_to_remove =
      Enum.filter(current_student_ids, fn elem -> not Enum.member?(new_student_ids, elem) end)

    Enum.each(student_ids_to_add, fn student_id ->
      %TeamMember{}
      # Change here
      |> Ecto.Changeset.change(%{team_id: team_id, student_id: student_id})
      |> Repo.insert()
    end)

    Enum.each(student_ids_to_remove, fn student_id ->
      Repo.delete_all(
        from(tm in TeamMember, where: tm.team_id == ^team_id and tm.student_id == ^student_id)
      )
    end)
  end

  @doc """
  Deletes a team along with its associated submissions and answers.

  ## Parameters

    * `team` - The team to be deleted

  """
  def delete_team(team = %Team{}) do
    Logger.info("Deleting team #{team.id} for assessment #{team.assessment_id}")

    if has_submitted_answer?(team.id) do
      Logger.error("Cannot delete team #{team.id} - team has submitted answers")
      {:error, {:conflict, "This team has submitted their answers! Unable to delete the team!"}}
    else
      submission =
        Submission
        |> where(team_id: ^team.id)
        |> Repo.one()

      if submission do
        Submission
        |> where(team_id: ^team.id)
        |> Repo.all()
        |> Enum.each(fn x ->
          Answer
          |> where(submission_id: ^x.id)
          |> Repo.delete_all()
        end)

        Notification
        |> where(submission_id: ^submission.id)
        |> Repo.delete_all()
      end

      result =
        team
        |> Repo.delete()

      case result do
        {:ok, _} ->
          Logger.info("Successfully deleted team #{team.id}")
          result

        {:error, changeset} ->
          Logger.error("Failed to delete team #{team.id}: #{full_error_messages(changeset)}")
          result
      end
    end
  end

  defp has_submitted_answer?(team_id) do
    submission =
      Submission
      |> where([s], s.team_id == ^team_id and s.status == :submitted)
      |> Repo.all()

    length(submission) > 0
  end

  @doc """
  Get the first member of a team.

  ## Parameters

    * `team_id` - The team id of the team to get the first member from.

  ## Returns

  Returns the first member of the team.

  """

  def get_first_member(team_id) do
    TeamMember
    |> where([tm], tm.team_id == ^team_id)
    |> limit(1)
    |> Repo.one()
  end
end
