defmodule Cadet.Repo.Migrations.CreateSubmissions do
  use Ecto.Migration

  alias Cadet.Assessments.SubmissionStatus

  def change do
    SubmissionStatus.create_type()

    create table(:submissions) do
      add(:status, :status)
      add(:submitted_at, :datetime)
      add(:override_xp, :integer)
      add(:assessment_id, references(:assessments))
      add(:student_id, references(:users))
      add(:grader_id, references(:users))
      timestamps()
    end
  end
end
