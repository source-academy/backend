defmodule Cadet.Repo.Migrations.CreateAchievementPrerequisites do
  use Ecto.Migration

  def change do
    create table(:achievement_prerequisites, primary_key: false) do
      add(:achievement_id, references(:achievements, on_delete: :delete_all),
        null: false,
        primary_key: true
      )

      add(:prerequisite_id, references(:achievements, on_delete: :delete_all),
        null: false,
        primary_key: true
      )
    end
  end
end
