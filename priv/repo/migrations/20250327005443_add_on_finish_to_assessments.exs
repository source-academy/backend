defmodule Cadet.Repo.Migrations.AddOnFinishToAssessments do
  use Ecto.Migration

  def change do
    alter table(:assessments) do
      add(:on_finish, :string, null: "")
    end
  end
end
