defmodule Cadet.Repo.Migrations.CreateAnswersTable do
  use Ecto.Migration

  def change do
    create table(:answers) do
      add(:grade, :integer, default: 0)
      add(:answer, :map, null: false)
      add(:submission_id, references(:submissions), null: false)
      add(:question_id, references(:questions), null: false)
      add(:comment, :text)
      add(:adjustment, :integer, default: 0)

      timestamps()
    end

    create(
      unique_index(
        :answers,
        [:submission_id, :question_id],
        name: :answers_submission_id_question_id_index
      )
    )

    create(index(:answers, [:submission_id]))
    create(index(:answers, [:question_id]))
  end
end
