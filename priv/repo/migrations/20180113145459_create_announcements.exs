defmodule Cadet.Repo.Migrations.CreateAnnouncements do
  use Ecto.Migration

  def change do
    create table(:announcements) do
      add(:title, :string, null: false)
      add(:content, :text)
      add(:pinned, :boolean)
      add(:published, :boolean)

      add(:poster_id, references(:users))

      timestamps()
    end
  end
end
