defmodule Cadet.Repo.Migrations.CreateDevices do
  use Ecto.Migration

  def change do
    create table(:devices) do
      add(:secret, :string, null: false)
      add(:type, :string, null: false)

      add(:client_key, :bytea, null: true, default: nil)
      add(:client_cert, :bytea, null: true, default: nil)

      timestamps()
    end

    create(unique_index(:devices, [:secret]))

    create table(:device_registrations) do
      add(:title, :string, null: false)

      add(:user_id, references(:users), null: false)
      add(:device_id, references(:devices), null: false)

      timestamps()
    end

    create(index(:device_registrations, [:user_id]))
  end
end
