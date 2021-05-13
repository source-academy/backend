defmodule Cadet.Repo.Migrations.ChangeAchievements do
  use Ecto.Migration

  def change do
    rename(table(:goals), :max_xp, to: :target_count)

    rename(table(:goal_progress), :xp, to: :count)

    alter table(:achievements) do
      add(:xp, :integer, null: false, default: 0)
      add(:is_variable_xp, :boolean, null: false, default: false)
    end
  end
end
