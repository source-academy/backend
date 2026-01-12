defmodule Cadet.Repo.Migrations.AddLlmGradingAccess do
  use Ecto.Migration

  def up do
    alter table(:courses) do
      add(:enable_llm_grading, :boolean, null: true)
    end
  end

  def down do
    alter table(:courses) do
      remove(:enable_llm_grading)
    end
  end
end
