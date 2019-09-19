defmodule Cadet.Repo.Migrations.UpdateAssessmentTypeEnum do
  use Ecto.Migration

  @disable_ddl_transaction true

  def change do
    Ecto.Migration.execute("ALTER TYPE assessment_type ADD VALUE IF NOT EXISTS 'practical'")
  end
end
