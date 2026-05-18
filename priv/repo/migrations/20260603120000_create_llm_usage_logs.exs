defmodule Cadet.Repo.Migrations.CreateLlmUsageLogs do
  use Ecto.Migration

  def change do
    create table(:llm_usage_logs) do
      add(:course_id, references(:courses, on_delete: :delete_all), null: false)
      add(:assessment_id, references(:assessments, on_delete: :delete_all), null: false)
      add(:question_id, references(:questions, on_delete: :delete_all), null: false)
      add(:answer_id, references(:answers, on_delete: :delete_all), null: false)
      add(:submission_id, references(:submissions, on_delete: :delete_all), null: false)
      add(:user_id, references(:users, on_delete: :nilify_all), null: false)

      timestamps()
    end

    create(index(:llm_usage_logs, [:course_id]))
    create(index(:llm_usage_logs, [:assessment_id]))
    create(index(:llm_usage_logs, [:user_id]))
    create(index(:llm_usage_logs, [:submission_id]))
  end
end
