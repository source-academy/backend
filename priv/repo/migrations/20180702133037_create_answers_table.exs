defmodule Cadet.Repo.Migrations.CreateAnswersTable do
  use Ecto.Migration

  def change do
    create table(:answers) do
      add(:marks, :float, default: 0.0)
      add(:answer, :map)
      add(:submission_id, references(:submissions))
      add(:question_id, references(:questions))
    end

    create(unique_index(:answers, [:submission_id, :question_id]))
  end
end
