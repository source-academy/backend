defmodule Cadet.Repo.Migrations.CreateSharedPrograms do
  use Ecto.Migration

  def change do
    create table(:shared_programs) do
      add :uuid, :uuid
      add :data, :map

      timestamps()
    end
  end
end
