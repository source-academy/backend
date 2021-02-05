defmodule Cadet.Repo.Migrations.AddSubmissionVotesTable do
  use Ecto.Migration

  def change do
    create table(:submission_votes) do
      add(:score, :integer)
      add(:user_id, references(:users), null: false)
      add(:submission_id, references(:submissions), null: false)
      add(:assessment_id, references(:assessments), null: false)
      timestamps()
    end

    create(unique_index(:submission_votes, [:user_id, :submission_id, :assessment_id]))
  end
end
