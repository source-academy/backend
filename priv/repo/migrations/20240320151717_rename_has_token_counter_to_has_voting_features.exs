defmodule Cadet.Repo.Migrations.RenameHasTokenCounterToHasVotingFeatures do
  use Ecto.Migration

  def change do
    rename(table(:assessment_configs), :has_token_counter, to: :has_voting_features)
  end
end
