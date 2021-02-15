defmodule Cadet.Repo.Migrations.ReworkAchievements do
  use Ecto.Migration

  def change do
    drop_if_exists(table(:achievement_prerequisites))
    drop_if_exists(table(:achievement_progress))
    drop_if_exists(table(:achievement_goals))
    drop_if_exists(table(:achievements))

    execute("CREATE EXTENSION IF NOT EXISTS \"uuid-ossp\"")

    create table(:achievements, primary_key: false) do
      add(:uuid, :uuid, null: false, default: fragment("uuid_generate_v4()"), primary_key: true)

      add(:title, :text, null: false)
      add(:ability, :text, null: false, default: "Core")
      add(:card_tile_url, :text)

      add(:open_at, :timestamp, default: fragment("NOW()"))
      add(:close_at, :timestamp, default: fragment("NOW()"))
      add(:is_task, :boolean, null: false, default: false)
      add(:position, :integer, null: false, default: 0)

      add(:canvas_url, :text)
      add(:description, :text)
      add(:completion_text, :text)
    end

    create(index(:achievements, [:open_at]))
    create(index(:achievements, [:close_at]))

    create table(:goals, primary_key: false) do
      add(:uuid, :uuid, null: false, default: fragment("uuid_generate_v4()"), primary_key: true)

      add(:text, :text, null: false)
      add(:max_xp, :integer, null: false)

      add(:type, :text, null: false)
      add(:meta, :map, null: false)
    end

    create table(:achievement_prerequisites, primary_key: false) do
      add(
        :achievement_uuid,
        references(:achievements, column: :uuid, type: :uuid, on_delete: :delete_all),
        null: false,
        primary_key: true
      )

      add(
        :prerequisite_uuid,
        references(:achievements, column: :uuid, type: :uuid, on_delete: :delete_all),
        null: false,
        primary_key: true
      )
    end

    create table(:achievement_to_goal, primary_key: false) do
      add(
        :achievement_uuid,
        references(:achievements, column: :uuid, type: :uuid, on_delete: :delete_all),
        null: false,
        primary_key: true
      )

      add(:goal_uuid, references(:goals, column: :uuid, type: :uuid, on_delete: :delete_all),
        null: false,
        primary_key: true
      )
    end

    create table(:goal_progress, primary_key: false) do
      add(:xp, :integer, null: false, default: 0)
      add(:completed, :boolean, null: false, default: false)

      add(:user_id, references(:users, on_delete: :delete_all), null: false, primary_key: true)

      add(:goal_uuid, references(:goals, column: :uuid, type: :uuid, on_delete: :delete_all),
        null: false,
        primary_key: true
      )

      timestamps()
    end
  end
end
