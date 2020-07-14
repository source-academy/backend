defmodule Cadet.Repo.Migrations.CreateStoriesTable do
  use Ecto.Migration

  def change do
    create table(:stories) do
      add(:open_at, :timestamp, null: false)
      add(:close_at, :timestamp, null: false)
      add(:is_published, :boolean, null: false, default: false)
      add(:title, :string, null: false)
      add(:image_url, :string, null: false)
      add(:filenames, {:array, :string}, null: false)
      timestamps()
    end

    create(index(:stories, [:open_at]))
    create(index(:stories, [:close_at]))
    create(index(:stories, [:is_published]))
  end
end
