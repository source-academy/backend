defmodule Cadet.Repo.Migrations.AddHasTokenCounterToggleToAssessment do
  use Ecto.Migration

  def up do
    alter table(:assessments) do
      add(:has_token_counter, :boolean, null: false, default: false)
      add(:has_voting_features, :boolean, null: false, default: false)
    end
  end

  def down do
    alter table(:assessments) do
      remove(:has_token_counter)
      remove(:has_voting_features)
    end
  end
end
