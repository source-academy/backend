defmodule Cadet.Repo.Migrations.AddLlmApiKeyToCourses do
  use Ecto.Migration

  def up do
    alter table(:courses) do
      add(:llm_api_key, :text, null: true)
      add(:llm_model, :text, null: false, default: "gpt-5-mini")
      add(:llm_api_url, :text, null: false, default: "https://api.openai.com/v1/chat/completions")
    end
  end

  def down do
    alter table(:courses) do
      remove(:llm_api_key)
      remove(:llm_model)
      remove(:llm_api_url)
    end
  end
end
