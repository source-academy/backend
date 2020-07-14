defmodule Cadet.Repo.Migrations.CreateAchievements do
  use Ecto.Migration

  alias Cadet.Achievements.{AchievementAbility, AchievementGoal}

  def change do
    AchievementAbility.create_type()

    create table(:achievements) do
      add(:title, :string)
      add(:inferencer_id, :integer)
      add(:ability, :achievement_ability, default: "Core")
      add(:background_image_url, :string)
      add(:open_at, :timestamp, default: fragment("NOW()"))
      add(:close_at, :timestamp, default: fragment("NOW()"))
      add(:is_task, :boolean, default: false)
      add(:prerequisite_ids, {:array, :integer})
      add(:position, :integer)

      add(:modal_image_url, :string,
        default:
          "https://www.publicdomainpictures.net/pictures/30000/velka/plain-white-background.jpg"
      )

      add(:description, :string)
      add(:completion_text, :text)

      timestamps()
    end

    create(index(:achievements, [:open_at]))
    create(index(:achievements, [:close_at]))
    create(index(:achievements, [:is_task]))
    create(index(:achievements, [:ability]))
  end
end
