defmodule Cadet.Repo.Migrations.RemoveNotNullFromLeaderInGroup do
  use Ecto.Migration

  def change do
    drop(unique_index(:groups, [:leader_id]))
    create(index(:groups, [:leader_id]))
  end
end
