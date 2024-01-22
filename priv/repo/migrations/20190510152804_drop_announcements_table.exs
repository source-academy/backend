defmodule Cadet.Repo.Migrations.DropAnnouncementsTable do
  use Ecto.Migration

  def change do
    drop_if_exists(table(:announcements))
  end
end
