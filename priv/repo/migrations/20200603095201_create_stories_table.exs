defmodule Cadet.Repo.Migrations.CreateStoriesTable do
  use Ecto.Migration

  def change do
    create table(:stories) do
      add(:filename, :string, null: false)
      add(:open_at, :timestamp, null: false)
      add(:close_at, :timestamp, null: false)
      add(:is_published, :boolean, null: false)
      timestamps()
    end

    create(index(:stories, [:filename]))
    create(index(:stories, [:open_at]))
    create(index(:stories, [:close_at]))
    create(index(:stories, [:is_published]))
  end
end
