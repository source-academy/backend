defmodule Cadet.Repo.Migrations.CreateGroups do
  use Ecto.Migration

  def change do
    create table(:groups) do
      add(:leader_id, references(:users, on_delete: :delete_all, null: false))
      add(:student_id, references(:users, on_delete: :delete_all, null: false))
    end

    create(index(:groups, [:leader_id]))
  end
end
