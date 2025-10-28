defmodule Cadet.Repo.Migrations.AddLlmAssessmentPromptAssessment do
  use Ecto.Migration

  def change do
    alter table(:assessments) do
      add(:llm_assessment_prompt, :text, default: nil)
    end
  end
end
