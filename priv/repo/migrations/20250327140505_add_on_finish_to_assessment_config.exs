defmodule Cadet.Repo.Migrations.AddOnFinishToAssessmentConfig do
  use Ecto.Migration

  def change do
    alter table(:assessment_configs) do
      add(:on_finish_submit_and_return_to_game, :boolean, default: false)
    end
  end
end
