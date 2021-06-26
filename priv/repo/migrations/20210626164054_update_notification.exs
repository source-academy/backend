defmodule Cadet.Repo.Migrations.UpdateNotification do
  use Ecto.Migration

  def change do
    alter table(:notifications) do
      remove(:user_id)
      add(:course_reg_id, references(:course_registrations), null: false)
    end
  end
end
