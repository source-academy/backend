defmodule Cadet.Repo.Migrations.AlterCoursesTableAddIsOfficialCourse do
  use Ecto.Migration

  def change do
    alter table(:courses) do
      add(:is_official_course, :boolean, null: false, default: false)
    end
  end
end
