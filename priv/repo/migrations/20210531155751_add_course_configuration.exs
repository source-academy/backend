defmodule Cadet.Repo.Migrations.AddCourseConfiguration do
  use Ecto.Migration

  def change do
    create table(:courses) do
      add(:name, :string, null: false)
      add(:module_code, :string)
      add(:viewable, :boolean, null: false, default: true)
      add(:enable_game, :boolean, null: false, default: true)
      add(:enable_achievements, :boolean, null: false, default: true)
      add(:enable_sourcecast, :boolean, null: false, default: true)
      add(:source_chapter, :integer, null: false)
      add(:source_variant, :string, null: false)
      add(:module_help_text, :string)
      timestamps()
    end

    create table(:assessment_configs) do
      add(:early_submission_xp, :integer, null: false)
      add(:hours_before_early_xp_decay, :integer, null: false)
      add(:decay_rate_points_per_hour, :integer, null: false)
      add(:course_id, references(:courses), null: false)
      timestamps()
    end

    create table(:assessment_types) do
      add(:order, :integer, null: false)
      add(:type, :string, null: false)
      add(:course_id, references(:courses), null: false)
      timestamps()
    end

    drop_if_exists(table(:sublanguages))
  end
end
