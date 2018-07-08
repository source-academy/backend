defmodule Cadet.Repo.Migrations.CreateUsers do
  use Ecto.Migration

  alias Cadet.Accounts.Role

  def up do
    Role.create_type()

    create table(:users) do
      add(:name, :string, null: false)
      add(:role, :role, null: false)
      add(:nusnet_id, :string)
      timestamps()
    end

    create(unique_index(:users, [:nusnet_id]))
  end

  def down do
    drop(table(:users))
    Role.drop_type()
  end
end
