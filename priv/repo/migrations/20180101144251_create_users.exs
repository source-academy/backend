defmodule Cadet.Repo.Migrations.CreateUsers do
  use Ecto.Migration

  alias Cadet.Accounts.Role

  def up do
    Role.create_type()

    create table(:users) do
      add(:first_name, :string, null: false)
      add(:last_name, :string)
      add(:role, :role, null: false)
      timestamps()
    end
  end

  def down do
    drop(table(:users))
    Role.drop_type()
  end
end
