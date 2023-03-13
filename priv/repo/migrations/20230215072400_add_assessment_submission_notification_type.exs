defmodule Cadet.Repo.Migrations.AddAssessmentSubmissionNotificationType do
  use Ecto.Migration

  def up do
    execute(
      "INSERT INTO notification_types (name, template_file_name, is_autopopulated, inserted_at, updated_at) VALUES ('ASSESSMENT SUBMISSION', 'assessment_submission', FALSE, current_timestamp, current_timestamp)"
    )
  end

  def down do
    execute("DELETE FROM notification_types WHERE name = 'ASSESSMENT SUBMISSION'")
  end
end
