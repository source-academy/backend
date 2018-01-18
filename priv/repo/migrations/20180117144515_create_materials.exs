defmodule Cadet.Repo.Migrations.CreateMaterials do
  use Ecto.Migration

  def change do
    create table(:materials) do
      add(:name, :string, null: false)
      add(:description, :string)
      add(:parent_id, references(:materials, on_delete: :delete_all))
      add(:uploader_id, references(:users, on_delete: :nilify_all))
      add(:file, :string)

      timestamps()
    end

    create(index(:materials, [:parent_id, :name]))
  end
end
