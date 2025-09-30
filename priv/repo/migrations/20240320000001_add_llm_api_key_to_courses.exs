defmodule Cadet.Repo.Migrations.AddLlmApiKeyToCourses do
  use Ecto.Migration

  def up do
    alter table(:courses) do
      add(:llm_api_key, :text, null: true)
    end
  end

  def down do
    alter table(:courses) do
      remove(:llm_api_key)
    end
  end
end
