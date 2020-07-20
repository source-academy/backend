defmodule Cadet.Repo.Migrations.CreateAchievementProgress do
  use Ecto.Migration

  def change do
    create table(:achievement_progress) do
      add(:progress, :integer, default: 0)

      add(:user_id, references(:users, on_delete: :delete_all), null: false)
      add(:goal_id, references(:achievement_goals, on_delete: :delete_all), null: false)

      timestamps()
    end

    create(index(:achievement_progress, [:user_id, :goal_id], unique: true))
  end
end
