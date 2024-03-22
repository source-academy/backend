defmodule Cadet.Repo.Migrations.AddIsGradingAutoPublished do
  use Ecto.Migration

  def up do
    alter table(:assessment_configs) do
      add(:is_grading_auto_published, :boolean, null: false, default: false)
    end
  end

  def down do
    alter table(:assessment_configs) do
      remove(:is_grading_auto_published)
    end
  end
end
