defmodule Cadet.Repo.Migrations.AddFieldsToMission do
  use Ecto.Migration

  def change do
    alter table(:missions) do
      add(:max_xp, :integer, null: false)
      add(:file, :string, null: false)
      add(:library, :map, null: false)
      add(:questions, :map)

      timestamps()
    end
  end
end
