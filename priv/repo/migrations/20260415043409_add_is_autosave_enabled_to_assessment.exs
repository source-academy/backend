defmodule Cadet.Repo.Migrations.AddIsAutosveEnabledToAssessment do
  use Ecto.Migration

  def up do
    alter table(:assessments) do
      add(:is_autosave_enabled, :boolean, default: true)
    end
  end

  def down do
    alter table(:assessments) do
      remove(:is_autosave_enabled)
    end
  end
end
