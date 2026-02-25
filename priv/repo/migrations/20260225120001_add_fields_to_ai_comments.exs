defmodule Cadet.Repo.Migrations.AddFieldsToAiComments do
  use Ecto.Migration

  def change do
    alter table(:ai_comment_logs) do
      add :selected_indices, {:array, :integer}
      add :finalized_by_id, references(:users, on_delete: :nilify_all)
      add :finalized_at, :utc_datetime
    end

    create index(:ai_comment_logs, [:answer_id])
    create index(:ai_comment_logs, [:finalized_by_id])
  end
end
