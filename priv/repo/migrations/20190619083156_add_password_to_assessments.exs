defmodule Cadet.Repo.Migrations.AddPasswordToAssessments do
  use Ecto.Migration

  def change do
    alter table(:assessments) do
      add(:password, :text, null: true)
    end
  end
end
