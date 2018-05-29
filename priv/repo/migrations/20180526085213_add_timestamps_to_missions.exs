defmodule Cadet.Repo.Migrations.AddTimestampsToMissions do
  use Ecto.Migration

  def change do
    alter table(:missions) do
      timestamps()
    end
  end
end
