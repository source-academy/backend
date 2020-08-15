defmodule Cadet.Repo.Migrations.RemoveAssessmentTypeEnum do
  use Ecto.Migration

  def change do
    alter table(:assessments) do
      add(:type_new, :string)
    end

    Ecto.Migration.execute("UPDATE assessments SET type_new = type::text")

    alter table(:assessments) do
      modify(:type_new, :string, null: false)
      remove(:type)
    end

    rename(table(:assessments), :type_new, to: :type)

    Ecto.Migration.execute("DROP TYPE assessment_type")
  end
end
