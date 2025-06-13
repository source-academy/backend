defmodule Cadet.Repo.Migrations.CreateLlmChatsTable do
  use Ecto.Migration

  def change do
    create table(:llm_chats) do
      add(:user_id, references(:users), null: false)
      add(:messages, :jsonb, null: false)
      timestamps()
    end
  end
end
