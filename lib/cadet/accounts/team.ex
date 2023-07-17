defmodule Cadet.Accounts.Team do
  use Ecto.Schema
  import Ecto.Changeset

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

  def create_team(attrs) do
    assessment_id = attrs["assessment_id"]
    student_ids = attrs["student_ids"]

    %Team{}
    |> cast(attrs, [:assessment_id])
    |> validate_required([:assessment_id])
    |> foreign_key_constraint(:assessment_id)
    |> Repo.insert()
    |> case do
      {:ok, team} ->
        create_team_members(team, student_ids)
        {:ok, team}

      error ->
        error
    end
  end

  defp create_team_members(team, student_ids) do
    Enum.each(student_ids, fn student_id ->
      %TeamMember{}
      |> Ecto.Changeset.change(%{team_id: team.id, student_id: student_id})
      |> Repo.insert()
    end)
  end

  def update_team(%Team{} = team, attrs) do
    assessment_id = attrs["assessment_id"]
    student_ids = attrs["student_ids"]

    team
    |> cast(attrs, [:assessment_id])
    |> validate_required([:assessment_id])
    |> foreign_key_constraint(:assessment_id)
    |> Ecto.Changeset.change()
    |> Repo.update()
    |> case do
      {:ok, updated_team} ->
        update_team_members(updated_team, student_ids)
        {:ok, updated_team}

      error ->
        error
    end
  end

  defp update_team_members(team, student_ids) do
    current_student_ids = team.team_members |> Enum.map(&(&1.student_id))

    student_ids_to_add = List.difference(student_ids, current_student_ids)
    student_ids_to_remove = List.difference(current_student_ids, student_ids)

    Enum.each(student_ids_to_add, fn student_id ->
      %TeamMember{}
      |> Ecto.Changeset.change(%{team_id: team.id, student_id: student_id})
      |> Repo.insert()
    end)

    Enum.each(student_ids_to_remove, fn student_id ->
      team.team_members
      |> where([tm], tm.student_id == ^student_id)
      |> Repo.delete_all()
    end)
  end

  def delete_team(%Team{} = team) do
    team
    |> Ecto.Changeset.delete_assoc(:submission)
    |> Ecto.Changeset.delete_assoc(:team_members)
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
