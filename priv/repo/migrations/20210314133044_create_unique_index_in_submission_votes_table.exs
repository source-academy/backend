defmodule Cadet.Repo.Migrations.CreateUniqueIndexInSubmissionVotesTable do
  use Ecto.Migration

  def change do
    create(unique_index(:submission_votes, [:user_id, :question_id, :score], name: :unique_score))
  end
end
