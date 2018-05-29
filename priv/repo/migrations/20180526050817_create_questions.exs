defmodule Cadet.Repo.Migrations.CreateQuestions do
  use Ecto.Migration

  alias Cadet.Assessments.ProblemType

  def up do
    ProblemType.create_type()

    create table(:questions) do
      add(:display_order, :integer)
      add(:type, :type, null: false)
      add(:title, :string)
      add(:library, :map)
      add(:raw_library, :text)
      add(:question, :map, null: false)
      add(:raw_question, :string)
      add(:mission_id, references(:missions))
      timestamps()
    end
  end

  def down do
    drop(table(:questions))

    ProblemType.drop_type()
  end
end
