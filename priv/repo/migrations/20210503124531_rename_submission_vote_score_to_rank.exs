defmodule Cadet.Repo.Migrations.RenameSubmissionVoteScoreToRank do
  use Ecto.Migration

  def change do
    rename(table(:submission_votes), :score, to: :rank)
  end
end
