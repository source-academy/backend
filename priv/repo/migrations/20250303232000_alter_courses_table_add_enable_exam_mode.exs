defmodule Cadet.Repo.Migrations.AlterCoursesTableAddEnableExamMode do
  use Ecto.Migration

  def change do
    alter table(:courses) do
      add(:enable_exam_mode, :boolean, null: false, default: false)
    end
  end
end
