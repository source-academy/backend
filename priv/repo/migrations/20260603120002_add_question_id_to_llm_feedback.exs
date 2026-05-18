defmodule Cadet.Repo.Migrations.AddQuestionIdToLlmFeedback do
  use Ecto.Migration

  def change do
    alter table(:llm_feedback) do
      add(:question_id, references(:questions, on_delete: :delete_all))
    end

    create(index(:llm_feedback, [:question_id]))
  end
end
