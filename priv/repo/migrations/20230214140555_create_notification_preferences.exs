defmodule Cadet.Repo.Migrations.CreateNotificationPreferences do
  use Ecto.Migration

  def change do
    create table(:notification_preferences) do
      add(:is_enabled, :boolean, default: false, null: false)

      add(
        :notification_config_id,
        references(:notification_configs, on_delete: :delete_all, null: false),
        null: false
      )

      add(:time_option_id, references(:time_options, on_delete: :nothing), default: nil)
      add(:course_reg_id, references(:course_registrations, on_delete: :delete_all), null: false)

      timestamps()
    end
  end
end
