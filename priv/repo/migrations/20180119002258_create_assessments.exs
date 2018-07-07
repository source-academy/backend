defmodule Cadet.Repo.Migrations.CreateMissions do
  use Ecto.Migration

  alias Cadet.Assessments.AssessmentType

  def up do
    AssessmentType.create_type()

    create table(:assessments) do
      add(:order, :string, null: false)
      add(:type, :assessment_type, null: false)
      add(:title, :string, null: false)
      add(:summary_short, :text)
      add(:summary_long, :text)
      add(:open_at, :timestamp, null: false)
      add(:close_at, :timestamp, null: false)
      add(:cover_picture, :string)
      add(:mission_pdf, :string)
      add(:is_published, :boolean, null: false)
      add(:max_xp, :integer)
      add(:priority, :integer)
      timestamps()
    end

    create(index(:assessments, [:order], using: :hash))
    create(index(:assessments, [:open_at]))
    create(index(:assessments, [:close_at]))
  end

  def down do
    drop(index(:assessments, [:order]))
    drop(index(:assessments, [:open_at]))
    drop(index(:assessments, [:close_at]))
    drop(table(:assessments))

    AssessmentType.drop_type()
  end
end
