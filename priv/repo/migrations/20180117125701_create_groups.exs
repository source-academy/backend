defmodule Cadet.Repo.Migrations.CreateGroups do
  use Ecto.Migration

  def change do
    create table(:groups) do
      add(:leader_id, references(:users), null: false)
      add(:mentor_id, references(:users))
      add(:name, :string)
    end

    create(unique_index(:groups, [:leader_id]))
    create(index(:groups, [:mentor_id]))

    alter table(:users) do
      add(:group_id, references(:groups))
    end

    create(index(:users, [:group_id]))
  end
end
