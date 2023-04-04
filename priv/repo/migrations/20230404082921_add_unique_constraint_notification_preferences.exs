defmodule Cadet.Repo.Migrations.AddUniqueConstraintNotificationPreferences do
  use Ecto.Migration

  def change do
    create unique_index(:notification_preferences, [:notification_config_id, :course_reg_id], name: :single_preference_per_config)
  end
end
