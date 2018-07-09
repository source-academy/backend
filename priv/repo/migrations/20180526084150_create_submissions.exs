defmodule Cadet.Repo.Migrations.CreateSubmissions do
  use Ecto.Migration

  def change do
    create table(:submissions) do
      add(:assessment_id, references(:assessments), null: false)
      add(:student_id, references(:users), null: false)
      timestamps()
    end

    create(unique_index(:submissions, [:assessment_id, :student_id]))
  end
end
