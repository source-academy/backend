defmodule Cadet.Repo.Migrations.RemoveAssessmentGrade do
  use Ecto.Migration

  def change do
    alter table(:answers) do
      remove(:grade)
      remove(:adjustment)
    end

    alter table(:questions) do
      remove(:max_grade)
    end
  end
end
