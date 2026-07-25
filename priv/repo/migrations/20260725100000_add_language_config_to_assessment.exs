defmodule Cadet.Repo.Migrations.AddLanguageConfigToAssessment do
  use Ecto.Migration

  def up do
    alter table(:assessments) do
      add(:language_id, :string, default: nil)
      add(:evaluator_id, :string, default: nil)
    end
  end

  def down do
    alter table(:assessments) do
      remove(:language_id)
      remove(:evaluator_id)
    end
  end
end
