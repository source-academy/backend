defmodule Cadet.Repo.Migrations.NotificationTypesAddForStaffColumn do
  use Ecto.Migration

  def change do
    alter table(:notification_types) do
      add(:for_staff, :boolean, null: false, default: true)
    end
  end
end
