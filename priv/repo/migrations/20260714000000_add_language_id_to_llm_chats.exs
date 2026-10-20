defmodule Cadet.Repo.Migrations.AddLanguageIdToLlmChats do
  use Ecto.Migration

  def change do
    alter table(:llm_chats) do
      add(:language_id, :string)
    end
  end
end
