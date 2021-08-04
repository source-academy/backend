defmodule Cadet.Repo.Migrations.RemoveAchievementAbility do
  use Ecto.Migration

  def change do
    alter table(:achievements) do
      remove(:ability, :text, null: false, default: "Core")
    end
  end
end
