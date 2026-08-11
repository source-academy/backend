defmodule Cadet.Repo.Migrations.AddEnablePixelbotToCourses do
  use Ecto.Migration

  def up do
    alter table(:courses) do
      add(:enable_pixelbot, :boolean, null: false, default: false)
    end
  end

  def down do
    alter table(:courses) do
      remove(:enable_pixelbot)
    end
  end
end
