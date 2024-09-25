defmodule Cadet.Repo.Migrations.AddHasVotingFeaturesToggleToAssessmentConfig do
  use Ecto.Migration

  def up do
    alter table(:assessment_configs) do
      add(:has_voting_features, :boolean, null: false, default: false)
    end
  end

  def down do
    alter table(:assessment_configs) do
      remove(:has_voting_features)
    end
  end
end
