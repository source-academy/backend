defmodule Cadet.Repo.Migrations.AddStoriesToggleToCourseConfig do
  use Ecto.Migration

  def up do
    alter table(:courses) do
      add(:enable_stories, :boolean, null: false, default: false)
    end
  end

  def down do
    alter table(:courses) do
      remove(:enable_stories)
    end
  end
end
