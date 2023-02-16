defmodule Cadet.Repo.Migrations.CreateSentNotifications do
  use Ecto.Migration

  def change do
    create table(:sent_notifications) do
      add(:content, :text)
      add(:course_reg_id, references(:course_registrations, on_delete: :nothing))

      timestamps()
    end

    create(index(:sent_notifications, [:course_reg_id]))
  end
end
