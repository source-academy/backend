defmodule Cadet.Repo.Migrations.AddCategoryIdToMaterials do
  use Ecto.Migration

  def change do
    alter table(:materials) do
      add(:category_id, references(:categories, on_delete: :delete_all))
    end
  end
end
