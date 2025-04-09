defmodule Cadet.Repo.Migrations.AlterCoursesTableAddResumeCode do
  use Ecto.Migration

  def change do
    alter table(:courses) do
      add(:resume_code, :string, null: false, default: "resume_code")
    end
  end
end
