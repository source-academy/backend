defmodule Cadet.Repo.Migrations.CreatePages do
  use Ecto.Migration

  def change do
    create table(:pages) do
      add(:user_id, references(:users, on_delete: :nothing), null: false)

      add(:course_registration_id, references(:course_registrations, on_delete: :nothing),
        null: true
      )

      add(:course_id, references(:courses, on_delete: :nothing), null: true)
      add(:path, :string, null: false)
      add(:time_spent, :integer, null: false)

      timestamps()
    end
  end
end
