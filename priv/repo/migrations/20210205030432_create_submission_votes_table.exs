defmodule Cadet.Repo.Migrations.AddSubmissionVotesTable do
  use Ecto.Migration

  def change do
    create table(:submission_votes) do
      add(:rank, :integer)
      add(:user_id, references(:users), null: false)
      add(:submission_id, references(:submissions), null: false)
      add(:question_id, references(:questions), null: false)
      timestamps()
    end

    create(unique_index(:submission_votes, [:user_id, :question_id, :rank], name: :unique_score))
  end
end
