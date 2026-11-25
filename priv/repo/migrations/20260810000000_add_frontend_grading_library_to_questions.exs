defmodule Cadet.Repo.Migrations.AddFrontendGradingLibraryToQuestions do
  use Ecto.Migration

  def up do
    alter table(:questions) do
      add(:frontend_grading_library, :map)
    end
  end

  def down do
    alter table(:questions) do
      remove(:frontend_grading_library)
    end
  end
end
