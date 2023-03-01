defmodule Cadet.Repo.Migrations.CreateSentNotifications do
  use Ecto.Migration

  def change do
    create table(:sent_notifications) do
      add(:content, :text, null: false)
      add(:course_reg_id, references(:course_registrations, on_delete: :nothing), null: false)

      timestamps()
    end

    create(index(:sent_notifications, [:course_reg_id]))
  end
end
