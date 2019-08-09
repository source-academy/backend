defmodule Cadet.Repo.Migrations.UpdateMaterials do
  use Ecto.Migration

  def change do
    drop(index(:materials, [:parent_id, :name]))
    create(index(:materials, [:uploader_id]))

    alter table(:materials) do
      remove(:parent_id)
      add(:category_id, references(:categories, on_delete: :delete_all))
    end

    rename(table(:materials), :name, to: :title)
  end
end
