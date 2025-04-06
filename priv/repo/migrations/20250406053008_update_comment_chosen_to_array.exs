defmodule Cadet.Repo.Migrations.UpdateCommentChosenToArray do
  use Ecto.Migration

  def change do
    alter table(:ai_comment_logs) do
      add(:comment_chosen_temp, {:array, :string}, default: [])
    end

    execute("UPDATE ai_comment_logs SET comment_chosen_temp = ARRAY[comment_chosen]")

    alter table(:ai_comment_logs) do
      remove(:comment_chosen)
    end

    rename(table(:ai_comment_logs), :comment_chosen_temp, to: :comment_chosen)
  end
end
