defmodule Cadet.Repo.Migrations.CreateAchievementPrerequisites do
  use Ecto.Migration

  alias Cadet.Achievements.{AchievementPrerequisite, Achievement}

  def change do
    create table(:achievement_prerequisites) do
      add(:inferencer_id, :integer)
      add(:achievement_id, references(:achievements), on_delete: :delete_all)

      timestamps()
    end
  end
end
