defmodule Cadet.Repo.Migrations.CreateTeamsSubmissionConstraint do
  use Ecto.Migration

  def change do
    create(index(:submissions, :team_id))
    create(unique_index(:submissions, [:assessment_id, :team_id]))
  end
end
