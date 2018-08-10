defmodule Cadet.Repo.Migrations.AddIndexQuestionsTableAssessmentId do
  use Ecto.Migration

  def change do
    create(index(:questions, [:assessment_id]))
  end
end
