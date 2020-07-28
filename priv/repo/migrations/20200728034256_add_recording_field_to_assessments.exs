defmodule Cadet.Repo.Migrations.AddRecordingFieldToAssessments do
  use Ecto.Migration

  def change do
    alter table(:assessments) do
      add(:is_recording, :boolean, null: false, default: false)
    end
  end
end
