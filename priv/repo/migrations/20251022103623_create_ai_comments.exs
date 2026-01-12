defmodule Cadet.Repo.Migrations.CreateAiCommentLogs do
  use Ecto.Migration

  def change do
    create table(:ai_comment_logs) do
      add(:answer_id, references(:answers, on_delete: :delete_all), null: false)
      add(:raw_prompt, :text, null: false)
      add(:answers_json, :text, null: false)
      add(:response, :text)
      add(:error, :text)
      add(:final_comment, :text)
      timestamps()
    end
  end
end
