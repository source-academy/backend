defmodule Cadet.Repo.Migrations.IncreaseLlmApiKeyLength do
  use Ecto.Migration

  def change do
    alter table(:courses) do
      modify(:llm_api_key, :text)
    end
  end
end
