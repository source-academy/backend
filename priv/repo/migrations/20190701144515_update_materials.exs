defmodule Cadet.Repo.Migrations.UpdateMaterials do
  use Ecto.Migration

  def change do
    drop(index(:materials, [:parent_id, :name]))
    create(index(:materials, [:uploader_id]))

    alter table(:materials) do
      remove(:parent_id)
    end

    rename(table(:materials), :name, to: :title)
  end
end
