defmodule Cadet.Repo.Migrations.CreateSubmissions do
  use Ecto.Migration

  def change do
    create table(:submissions) do
      add(:assessment_id, references(:assessments))
      add(:student_id, references(:users))
      add(:grader_id, references(:users))
      timestamps()
    end
  end
end
