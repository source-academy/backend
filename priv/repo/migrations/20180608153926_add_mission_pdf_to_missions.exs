defmodule Cadet.Repo.Migrations.AddMissionPDFToMissions do
  use Ecto.Migration

  def change do
    alter table(:missions) do
      add(:mission_pdf, :string)
    end
  end
end
