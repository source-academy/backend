defmodule Cadet.Repo.Migrations.RemoveMaterials do
  use Ecto.Migration

  def change do
    drop_if_exists(table(:materials))
    drop_if_exists(table(:categories))
  end
end
