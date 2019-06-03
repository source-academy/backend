defmodule Cadet.Repo.Migrations.AddNotifications do
  use Ecto.Migration

  def change do
    create table(:notifications) do
      add(:type, :string)
      add(:read, :boolean)
      add(:user_id, references(:users), null: false)
      add(:submission_id, references(:submissions), null: false)
      timestamps()
    end

    create(index(:notifications, [:user_id, :submission_id]))
  end
end
