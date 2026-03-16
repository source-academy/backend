defmodule Cadet.Repo.Migrations.RemoveDiffColumnsFromAiCommentVersions do
  use Ecto.Migration

  def change do
    alter table(:ai_comment_versions) do
      remove(:diff_json)
      remove(:diff_unified)
    end
  end
end
