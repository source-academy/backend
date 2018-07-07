defmodule Cadet.Repo.Migrations.CreateUserHeirarchies do
  use Ecto.Migration

  def change do
    create table(:user_heirarchies) do
      add(:slave_id, references(:users, on_delete: :delete_all), null: false)
      add(:master_id, references(:users, on_delete: :delete_all), null: false)
    end

    create(index(:user_heirarchies, [:slave_id]))
    create(index(:user_heirarchies, [:master_id]))
    create(unique_index(:user_heirarchies, [:slave_id, :master_id]))

    alter table(:users) do
      add(:user_heirarchy_id, references(:users))
    end

    create(index(:users, [:user_heirarchy_id]))
  end
end
