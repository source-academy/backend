defmodule Cadet.Repo.Migrations.CreateNotificationTypes do
  use Ecto.Migration

  def change do
    create table(:notification_types) do
      add(:name, :string, null: false)
      add(:template_file_name, :string, null: false)
      add(:is_enabled, :boolean, default: false, null: false)
      add(:is_autopopulated, :boolean, default: false, null: false)

      timestamps()
    end

    create(unique_index(:notification_types, [:name]))
  end
end
