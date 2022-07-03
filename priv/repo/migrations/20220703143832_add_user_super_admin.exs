defmodule Cadet.Repo.Migrations.AddUserSuperAdmin do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add(:super_admin, :boolean, null: false, default: false)
    end
  end
end
