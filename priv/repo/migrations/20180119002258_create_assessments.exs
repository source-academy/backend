defmodule Cadet.Repo.Migrations.CreateMissions do
  use Ecto.Migration

  alias Cadet.Assessments.AssessmentType

  def up do
    AssessmentType.create_type()

    create table(:assessments) do
      add(:title, :string, null: false)
      add(:summary_short, :text)
      add(:summary_long, :text)
      add(:type, :assessment_type, null: false)
      add(:open_at, :timestamp, null: false)
      add(:close_at, :timestamp, null: false)
      add(:cover_picture, :string)
      add(:number, :string)
      add(:story, :string)
      add(:reading, :string)
      add(:mission_pdf, :string)
      add(:is_published, :boolean, null: false)
      timestamps()
    end

    create(index(:assessments, [:open_at]))
    create(index(:assessments, [:close_at]))
    create(index(:assessments, [:is_published]))
    create(index(:assessments, [:type]))
  end

  def down do
    drop(table(:assessments))

    AssessmentType.drop_type()
  end
end
