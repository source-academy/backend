defmodule Cadet.Repo.Migrations.RemoveUniqueScoreConstraint do
  use Ecto.Migration

  def up do
    drop(unique_index(:submission_votes, [:user_id, :question_id, :score], name: :unique_score))
  end

  def down do
    create(unique_index(:submission_votes, [:user_id, :question_id, :score], name: :unique_score))
  end
end
