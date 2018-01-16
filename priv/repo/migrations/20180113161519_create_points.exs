defmodule Cadet.Repo.Migrations.CreatePoints do
  use Ecto.Migration

  def change do
    create table(:points) do
      add(:reason, :string, null: false)
      add(:amount, :integer, null: false)
      add(:given_to_id, references(:users))
      add(:given_by_id, references(:users))
      timestamps()
    end

    create(index(:points, [:given_to_id]))
    create(index(:points, [:given_by_id]))
  end
end
