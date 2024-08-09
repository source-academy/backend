defmodule Cadet.Repo.Migrations.AddPrependContextToLlmChatroom do
  use Ecto.Migration

  def change do
    alter table(:llm_chats) do
      add(:prepend_context, :jsonb, null: false)
    end
  end
end
