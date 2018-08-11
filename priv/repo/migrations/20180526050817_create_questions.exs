defmodule Cadet.Repo.Migrations.CreateQuestions do
  use Ecto.Migration

  alias Cadet.Assessments.QuestionType

  def up do
    QuestionType.create_type()

    create table(:questions) do
      add(:display_order, :integer)
      add(:type, :question_type, null: false)
      add(:title, :string)
      add(:library, :map)
      add(:grading_library, :map)
      add(:question, :map, null: false)
      add(:max_grade, :integer, default: 0)
      add(:assessment_id, references(:assessments), null: false)
      timestamps()
    end
  end

  def down do
    drop(table(:questions))

    QuestionType.drop_type()
  end
end
