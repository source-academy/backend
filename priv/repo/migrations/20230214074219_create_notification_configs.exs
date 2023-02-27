defmodule Cadet.Repo.Migrations.CreateNotificationConfigs do
  use Ecto.Migration

  def change do
    create table(:notification_configs) do
      add(:is_enabled, :boolean, default: false, null: false)

      add(:notification_type_id, references(:notification_types, on_delete: :delete_all),
        null: false
      )

      add(:course_id, references(:courses, on_delete: :delete_all), null: false)
      add(:assessment_config_id, references(:assessment_configs, on_delete: :delete_all))

      timestamps()
    end
  end
end
