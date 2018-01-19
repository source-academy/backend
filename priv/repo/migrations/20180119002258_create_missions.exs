defmodule Cadet.Repo.Migrations.CreateMissions do
  use Ecto.Migration

  alias Cadet.Assessments.Category

  def up do
    Category.create_type()

    create table(:missions) do
      add(:order, :string, null: false)
      add(:category, :category, null: false)
      add(:title, :string, null: false)
      add(:summary_short, :text)
      add(:summary_long, :text)
      add(:open_at, :timestamp, null: false)
      add(:close_at, :timestamp, null: false)
      add(:cover_picture, :string)
    end

    create(index(:missions, [:order], using: :hash))
    create(index(:missions, [:open_at]))
    create(index(:missions, [:close_at]))
  end

  def down do
    drop(index(:missions, [:order]))
    drop(index(:missions, [:open_at]))
    drop(index(:missions, [:close_at]))
    drop(table(:missions))

    Category.drop_type()
  end
end
