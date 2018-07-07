defmodule Cadet.Repo.Migrations.CreateUsers do
  use Ecto.Migration

  alias Cadet.Accounts.Role

  def up do
    Role.create_type()

    create table(:users) do
      add(:first_name, :string, null: false)
      add(:last_name, :string)
      add(:role, :role, null: false)
      add(:nusnet_id, :string)
      add(:user_heirarchy_id, references(:users))
      timestamps()
    end

    create(index(:users, [:user_heirarchy_id]))
    create(unique_index(:users, [:nusnet_id]))
  end

  def down do
    drop(unique_index(:users, [:nusnet_id]))
    drop(index(:users, [:user_heirarchy_id]))
    drop(table(:users))
    Role.drop_type()
  end
end
