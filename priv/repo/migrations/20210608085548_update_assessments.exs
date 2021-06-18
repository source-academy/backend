defmodule Cadet.Repo.Migrations.UpdateAssessments do
  use Ecto.Migration

  def change do
    alter table(:assessments) do
      remove(:type)
      add(:type_id, references(:assessment_types), null: false)
      add(:course_id, references(:courses), null: false)
    end

    alter table(:submissions) do
      remove(:student_id)
      add(:student_id, references(:course_registrations), null: false)
      remove(:unsubmitted_by_id)
      add(:unsubmitted_by_id, references(:course_registrations), null: true)
    end

    create(index(:submissions, :student_id))
    create(unique_index(:submissions, [:assessment_id, :student_id]))

    alter table(:groups) do
      remove(:leader_id)
      add(:leader_id, references(:course_registrations), null: false)
      remove(:mentor_id)
      add(:mentor_id, references(:course_registrations), null: true)
      add(:course_id, references(:courses), null: false)
    end

    create(unique_index(:groups, [:name, :course_id]))

    alter table(:users) do
      add(:latest_viewed_id, references(:courses), null: true)
    end

    alter table(:submission_votes) do
      remove(:user_id)
      add(:voter_id, references(:course_registrations), null: false)
    end
  end
end
