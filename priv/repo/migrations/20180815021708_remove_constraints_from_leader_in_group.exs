defmodule Cadet.Repo.Migrations.RemoveConstraintsFromLeaderInGroup do
  use Ecto.Migration

  def up do
    drop(unique_index(:groups, [:leader_id]))
    drop(constraint(:groups, "groups_leader_id_fkey"))

    alter table(:groups) do
      modify(:leader_id, references(:users), null: true)
    end
  end

  def down do
    create(unique_index(:groups, [:leader_id]))
    drop(constraint(:groups, "groups_leader_id_fkey"))

    alter table(:groups) do
      modify(:leader_id, references(:users), null: false)
    end
  end
end
