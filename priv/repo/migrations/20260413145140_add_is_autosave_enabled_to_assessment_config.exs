defmodule Cadet.Repo.Migrations.AddIsAutosaveEnabledToAssessmentConfig do
  use Ecto.Migration

  def up do
    alter table(:assessment_configs) do
      add(:is_autosave_enabled, :boolean, default: true)
    end
  end

  def down do
    alter table(:assessment_configs) do
      remove(:is_autosave_enabled)
    end
  end
end
