defmodule Cadet.Repo.Migrations.CreateLlmFeedback do
  use Ecto.Migration

  def change do
    create table(:llm_feedback) do
      add(:course_id, references(:courses, on_delete: :delete_all), null: false)
      add(:assessment_id, references(:assessments, on_delete: :delete_all))
      add(:user_id, references(:users, on_delete: :nilify_all), null: false)
      add(:rating, :integer)
      add(:body, :text, null: false)

      timestamps()
    end

    create(index(:llm_feedback, [:course_id]))
    create(index(:llm_feedback, [:assessment_id]))
    create(index(:llm_feedback, [:user_id]))
  end
end
