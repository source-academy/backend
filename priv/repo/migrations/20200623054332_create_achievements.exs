defmodule Cadet.Repo.Migrations.CreateAchievements do
  use Ecto.Migration

  alias Cadet.Achievements.AchievementAbility

  def change do
    AchievementAbility.create_type()

    create table(:achievements) do
      add(:title, :string)
      add(:inferencer_id, :integer)
      add(:ability, :achievement_ability)
      add(:background_image_url, :string)
      add(:exp, :integer)
      add(:open_at, :timestamp)
      add(:close_at, :timestamp)
      add(:is_task, :boolean)
      add(:prerequisite_ids, {:array, :integer})
      add(:goal, :integer)
      add(:progress, :integer)
      add(:position, :integer)
      add(:modal_image_url, :string)
      add(:description, :string)
      add(:goal_text, :text)
      add(:completion_text, :text)

      timestamps()
    end

    create(index(:achievements, [:open_at]))
    create(index(:achievements, [:close_at]))
    create(index(:achievements, [:is_task]))
    create(index(:achievements, [:ability]))
  end
end
