defmodule Cadet.Repo.Migrations.RenameLatestViewedId do
  use Ecto.Migration

  def change do
    rename(table(:users), :latest_viewed_id, to: :latest_viewed_course_id)
  end
end
