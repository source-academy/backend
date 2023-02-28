defmodule Cadet.Repo.Migrations.CreateTimeOptions do
  use Ecto.Migration

  def change do
    create table(:time_options) do
      add(:minutes, :integer, null: false)
      add(:is_default, :boolean, default: false, null: false)

      add(:notification_config_id, references(:notification_configs, on_delete: :delete_all),
        null: false
      )

      timestamps()
    end

    create(
      unique_index(:time_options, [:minutes, :notification_config_id], name: :unique_time_options)
    )
  end
end
