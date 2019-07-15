defmodule Cadet.Repo.Migrations.CreateCategories do
  use Ecto.Migration

  def change do
    create table(:categories) do
      add(:name, :string, null: false)
      add(:description, :string)
      add(:uploader_id, references(:users, on_delete: :nilify_all))
      add(:category_id, references(:categories, on_delete: :delete_all))
      timestamps()
    end
  end
end
