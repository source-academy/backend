defmodule Cadet.Repo.Migrations.AddGraderIdToAnswers do
  use Ecto.Migration

  def change do
    alter table(:answers) do
      add(:grader_id, references(:users), null: true)
    end
  end
end
