defmodule Cadet.Repo.Migrations.CreateAchievements do
  use Ecto.Migration

  def change do
    create table(:achievements, primary_key: false) do
      add(:id, :integer, null: false, primary_key: true)

      add(:title, :text, null: false)
      add(:ability, :text, null: false, default: "Core")
      add(:card_tile_url, :text)

      add(:open_at, :timestamp, default: fragment("NOW()"))
      add(:close_at, :timestamp, default: fragment("NOW()"))
      add(:is_task, :boolean, null: false, default: false)
      add(:position, :integer, null: false)

      add(:canvas_url, :text,
        default:
          "https://www.publicdomainpictures.net/pictures/30000/velka/plain-white-background.jpg"
      )

      add(:description, :text)
      add(:completion_text, :text)

      timestamps()
    end

    create(index(:achievements, [:open_at]))
    create(index(:achievements, [:close_at]))
  end
end
