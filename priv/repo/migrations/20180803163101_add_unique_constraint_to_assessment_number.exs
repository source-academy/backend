defmodule Cadet.Repo.Migrations.AddUniqueConstraintToAssessmentNumber do
  use Ecto.Migration

  def change do
    create(unique_index(:assessments, [:number]))
  end
end
