defmodule Cadet.Repo.Migrations.AddOnFinishToAssessmentConfig do
  use Ecto.Migration

  def change do
    alter table(:assessment_configs) do
      add(:is_minigame, :boolean, default: false)
    end
  end
end
