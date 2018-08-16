defmodule Cadet.Repo.Migrations.AddUniqueConstraintOnGroupNames do
  use Ecto.Migration

  def change do
    create(unique_index(:groups, [:name]))
  end
end
