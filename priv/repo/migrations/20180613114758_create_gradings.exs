defmodule Cadet.Repo.Migrations.CreateGradings do
  use Ecto.Migration

  def change do
    create table(:gradings) do
      add(:grading_infos, :map)

      timestamps()
    end
  end
end
