defmodule Cadet.Repo.Migrations.AddFieldsToMissions do
  use Ecto.Migration

  def change do
    alter table(:missions) do
      add(:is_published, :boolean, null: false)
      add(:max_xp, :integer)
      add(:priority, :integer)
    end
  end
end
