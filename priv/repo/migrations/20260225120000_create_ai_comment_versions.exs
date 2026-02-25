defmodule Cadet.Repo.Migrations.CreateAiCommentVersions do
  use Ecto.Migration

  def change do
    create table(:ai_comment_versions) do
      add(:ai_comment_id, references(:ai_comment_logs, on_delete: :delete_all), null: false)
      add(:comment_index, :integer, null: false)
      add(:version_number, :integer, null: false, default: 1)
      add(:editor_id, references(:users, on_delete: :nilify_all))
      add(:content, :text)
      add(:diff_json, :map)
      add(:diff_unified, :text)

      timestamps()
    end

    create(index(:ai_comment_versions, [:ai_comment_id]))
    create(index(:ai_comment_versions, [:editor_id]))
    create(unique_index(:ai_comment_versions, [:ai_comment_id, :comment_index, :version_number]))
  end
end
