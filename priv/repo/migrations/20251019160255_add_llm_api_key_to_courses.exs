defmodule Cadet.Repo.Migrations.AddLlmApiKeyToCourses do
  use Ecto.Migration

  def up do
    alter table(:courses) do
      add(:llm_api_key, :text, null: true)
      add(:llm_model, :text, null: true)
      add(:llm_api_url, :text, null: true)
      add(:llm_course_level_prompt, :text, null: true)
    end
  end

  def down do
    alter table(:courses) do
      remove(:llm_course_level_prompt)
      remove(:llm_api_key)
      remove(:llm_model)
      remove(:llm_api_url)
    end
  end
end
