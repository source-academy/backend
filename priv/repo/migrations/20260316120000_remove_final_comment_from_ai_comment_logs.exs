defmodule Cadet.Repo.Migrations.RemoveFinalCommentFromAiCommentLogs do
  use Ecto.Migration

  def change do
    alter table(:ai_comment_logs) do
      remove(:final_comment, :text)
    end
  end
end
