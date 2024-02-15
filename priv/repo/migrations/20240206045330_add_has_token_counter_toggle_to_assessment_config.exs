defmodule Cadet.Repo.Migrations.AddHasTokenCounterToggleToAssessmentConfig do
  use Ecto.Migration

  def up do
    alter table(:assessment_configs) do
      add(:has_token_counter, :boolean, null: false, default: false)
    end
  end

  def down do
    alter table(:assessment_configs) do
      remove(:has_token_counter)
    end
  end
end
