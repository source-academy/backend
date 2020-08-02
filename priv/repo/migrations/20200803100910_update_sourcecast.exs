defmodule Cadet.Repo.Migrations.UpdateSourcecast do
  use Ecto.Migration

  def change do
    alter table(:sourcecasts) do
      add(:uid, :string, null: false)
    end

    create(unique_index(:sourcecasts, [:uid]))
  end
end
