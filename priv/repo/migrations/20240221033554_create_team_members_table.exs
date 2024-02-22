defmodule Cadet.Repo.Migrations.CreateTeamMembersTable do
  use Ecto.Migration

  def change do
    create table(:team_members) do
      add(:team_id, references(:teams), null: false)
      add(:student_id, references(:course_registrations), null: false)
      timestamps()
    end
  end
end
