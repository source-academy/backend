defmodule Cadet.Repo.Migrations.CreateAiCommentLogs do
  use Ecto.Migration

  def change do
    create table(:ai_comment_logs) do
      add(:submission_id, references(:submissions, on_delete: :delete_all), null: false)
      add(:question_id, references(:questions, on_delete: :delete_all), null: false)
      add(:raw_prompt, :text, null: false)
      add(:answers_json, :text, null: false)
      add(:response, :text)
      add(:error, :text)
      add(:comment_chosen, :text)
      add(:final_comment, :text)
      timestamps()
    end

    create(index(:ai_comment_logs, [:submission_id]))
    create(index(:ai_comment_logs, [:question_id]))
  end
end
