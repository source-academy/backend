defmodule Cadet.Repo.Migrations.RemoveNotNullFromLeaderInGroup do
  use Ecto.Migration

  def up do
    drop(constraint(:groups, "groups_leader_id_fkey"))

    alter table(:groups) do
      modify(:leader_id, references(:users), null: true)
    end
  end

  def down do
    drop(constraint(:groups, "groups_leader_id_fkey"))

    alter table(:groups) do
      modify(:leader_id, references(:users), null: false)
    end
  end
end
