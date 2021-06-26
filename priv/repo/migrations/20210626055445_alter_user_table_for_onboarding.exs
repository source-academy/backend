defmodule Cadet.Repo.Migrations.AlterUserTableForOnboarding do
  use Ecto.Migration

  def up do
    alter table(:users) do
      modify(:name, :string, null: true)
      modify(:username, :string, null: false)
    end
  end

  def down do
    alter table(:users) do
      modify(:name, :string, null: false)
      modify(:username, :string, null: true)
    end
  end
end
