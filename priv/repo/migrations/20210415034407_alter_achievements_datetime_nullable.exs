defmodule Cadet.Repo.Migrations.AlterAchievementsDatetimeNullable do
  use Ecto.Migration

  def up do
    alter table(:achievements) do
      modify(:open_at, :timestamp, null: true, default: nil)
      modify(:close_at, :timestamp, null: true, default: nil)
    end
  end

  def down do
    alter table(:achievements) do
      modify(:open_at, :timestamp, default: fragment("NOW()"))
      modify(:close_at, :timestamp, default: fragment("NOW()"))
    end
  end
end
