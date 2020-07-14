defmodule Cadet.Repo.Migrations.CreateAchievementGoals do
  use Ecto.Migration

  alias Cadet.Achievements.{AchievementGoal, Achievement}

  def change do
    create table(:achievement_goals) do
      add(:goal_id, :integer)
      add(:goal_text, :string)
      add(:goal_progress, :integer, default: 0)
      add(:goal_target, :integer, default: 0)

      add(:achievement_id, references(:achievements), on_delete: :delete_all)
      add(:user_id, references(:users), on_delete: :delete_all)

      timestamps()
    end
  end
end
