defmodule Cadet.Repo.Migrations.CreateSubmissionsAssessmentIndex do
  use Ecto.Migration

  def up do
    create(index(:submissions, [:assessment_id]))
  end

  def down do
    drop(index(:submissions, [:assessment_id]))
  end
end
