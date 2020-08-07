defmodule Cadet.Repo.Migrations.UpdateSourcecast do
  use Ecto.Migration

  def change do
    execute("CREATE EXTENSION IF NOT EXISTS \"uuid-ossp\"")

    alter table(:sourcecasts) do
      add(:uid, :string, null: false, default: fragment("uuid_generate_v4()"))
    end

    create(unique_index(:sourcecasts, [:uid]))
  end
end
