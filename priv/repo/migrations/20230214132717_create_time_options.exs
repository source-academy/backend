defmodule Cadet.Repo.Migrations.CreateTimeOptions do
  use Ecto.Migration

  def change do
    create table(:time_options) do
      add(:minutes, :integer)
      add(:is_default, :boolean, default: false, null: false)
      add(:notification_config_id, references(:notification_configs, on_delete: :delete_all))

      timestamps()
    end
  end
end
