defmodule Cadet.Repo.Migrations.CreateSubmissionStatus do
  use Ecto.Migration

  alias Cadet.Assessments.SubmissionStatus

  def up do
    SubmissionStatus.create_type()

    alter table(:submissions) do
      add(:status, :submission_status, null: false, default: "attempting")
    end
  end

  def down do
    alter table(:submissions) do
      remove(:status)
    end

    SubmissionStatus.drop_type()
  end
end
