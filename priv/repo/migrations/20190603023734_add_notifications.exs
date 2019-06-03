defmodule Cadet.Repo.Migrations.AddNotifications do
  use Ecto.Migration

  def change do
    create table(:notifications) do
      add(:type, :string)
      add(:read, :boolean)
      add(:user_id, references(:users), null: false)
      add(:assessment_id, references(:assessments), null: false)
      add(:question_id, references(:questions), null: true)
      timestamps()
    end

    create(index(:notifications, [:user_id, :assessment_id]))
  end
end
