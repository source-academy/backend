defmodule Cadet.Repo.Migrations.CreateEnvironments do
  use Ecto.Migration

  def change do
    create table(:environments) do
      add(:name, :string, null: false)

      timestamps()
    end
  end
end
