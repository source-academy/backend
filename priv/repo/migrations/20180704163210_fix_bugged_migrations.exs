defmodule Cadet.Repo.Migrations.FixBuggedMigrations do
  use Ecto.Migration

  def change do
    drop(constraint(:answers, :answers_submission_id_fkey))
    drop(constraint(:answers, :answers_question_id_fkey))

    alter table(:answers) do
      modify(:submission_id, references(:submissions), null: false)
      modify(:question_id, references(:questions), null: false)
    end

    drop(constraint(:questions, :questions_assessment_id_fkey))

    alter table(:questions) do
      modify(:assessment_id, references(:assessments), null: false)
    end

    drop(constraint(:submissions, :submissions_assessment_id_fkey))
    drop(constraint(:submissions, :submissions_student_id_fkey))

    alter table(:submissions) do
      modify(:assessment_id, references(:assessments), null: false)
      modify(:student_id, references(:users), null: false)
    end
  end
end
