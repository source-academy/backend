defmodule Cadet.Repo.Migrations.CreateAchievements do
  use Ecto.Migration

  alias Cadet.Achievements.AchievementAbility

  def change do
    AchievementAbility.create_type()

    create table(:achievements) do
      add(:title, :string)
      add(:ability, :achievement_ability)
      add(:icon, :string)
      add(:exp, :integer)
      add(:open_at, :timestamp)
      add(:close_at, :timestamp)
      add(:is_task, :boolean)
      add(:prerequisiteIDs, {:array, :integer})
      add(:goal, :integer)
      add(:progress, :integer)

      add(:modalImageUrl, :string)
      add(:description, :string)
      add(:goalText, :string)
      add(:completionText, :string)

      timestamps()
    end

    create(index(:achievements, [:open_at]))
    create(index(:achievements, [:close_at]))
    create(index(:achievements, [:is_task]))
    create(index(:achievements, [:ability]))
  end
end
