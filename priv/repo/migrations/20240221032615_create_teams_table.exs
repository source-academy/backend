defmodule Cadet.Repo.Migrations.CreateTeamsTable do
  use Ecto.Migration

  def change do
    create table(:teams) do
      add(:assessment_id, references(:assessments), null: false)
      timestamps()
    end
  end
end
