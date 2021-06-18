defmodule Cadet.Repo.Migrations.AddCourseConfiguration do
  use Ecto.Migration

  alias Cadet.Accounts.Role

  def change do
    alter table(:users) do
      remove(:role)
      remove(:group_id)
      remove(:game_states)
    end

    create table(:courses) do
      add(:course_name, :string, null: false)
      add(:course_short_name, :string)
      add(:viewable, :boolean, null: false, default: true)
      add(:enable_game, :boolean, null: false, default: true)
      add(:enable_achievements, :boolean, null: false, default: true)
      add(:enable_sourcecast, :boolean, null: false, default: true)
      add(:source_chapter, :integer, null: false)
      add(:source_variant, :string, null: false)
      add(:module_help_text, :string)
      timestamps()
    end

    create table(:assessment_types) do
      add(:order, :integer, null: false)
      add(:type, :string, null: false)
      add(:course_id, references(:courses), null: false)
      add(:is_graded, :boolean, null: false)
      timestamps()
    end

    create(unique_index(:assessment_types, [:course_id, :order]))

    create table(:assessment_configs) do
      add(:early_submission_xp, :integer, null: false)
      add(:hours_before_early_xp_decay, :integer, null: false)
      add(:decay_rate_points_per_hour, :integer, null: false)
      add(:assessment_type_id, references(:assessment_types, on_delete: :delete_all), null: false)
      timestamps()
    end

    create table(:course_registrations) do
      add(:role, :role, null: false)
      add(:game_states, :map, default: %{})
      add(:group_id, references(:groups))
      add(:user_id, references(:users), null: false)
      add(:course_id, references(:courses), null: false)
      timestamps()
    end

    create(
      unique_index(:course_registrations, [:user_id, :course_id],
        name: :course_registrations_user_id_course_id_index
      )
    )

    drop_if_exists(table(:sublanguages))

    alter table(:sourcecasts) do
      add(:course_id, references(:courses))
    end

    alter table(:stories) do
      add(:course_id, references(:courses), null: false)
    end
  end
end
