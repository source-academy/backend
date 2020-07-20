defmodule Cadet.Repo.Migrations.CreateAchievementGoals do
  use Ecto.Migration

  def change do
    create table(:achievement_goals) do
      add(:order, :integer, null: false)
      add(:text, :text, null: false)
      add(:target, :integer, null: false)

      add(:achievement_id, references(:achievements, on_delete: :delete_all), null: false)
    end

    create(index(:achievement_goals, [:achievement_id, :order], unique: true))
  end
end
