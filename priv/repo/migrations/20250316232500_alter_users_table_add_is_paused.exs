defmodule Cadet.Repo.Migrations.AlterCoursesTableAddIsOfficialCourse do
  use Ecto.Migration

  def change do
      alter table(:users) do
        add(:is_paused, :boolean, null: false, default: false)
      end
  end
end
