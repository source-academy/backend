defmodule Cadet.Repo.Migrations.AddVariantToChapters do
  use Ecto.Migration

  def change do
    alter table(:chapters) do
      add(:variant, :string, null: false)
    end
  end
end
