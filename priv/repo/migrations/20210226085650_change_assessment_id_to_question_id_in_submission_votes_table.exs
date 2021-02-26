defmodule Cadet.Repo.Migrations.ChangeAssessmentIdToQuestionIdInSubmissionVotesTable do
  use Ecto.Migration

  def change do
    alter table("submission_votes") do
      add_if_not_exists(:question_id, references(:questions))
      remove_if_exists(:assessment_id, references(:assessments))
    end
  end
end
