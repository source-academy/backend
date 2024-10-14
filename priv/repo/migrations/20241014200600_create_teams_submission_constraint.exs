defmodule Cadet.Repo.Migrations.CreateTeamsSubmissionConstraint do
  use Ecto.Migration

  def up do
    create(
      unique_index(
        :submissions,
        [:team_id, :assessment_id],
        name: :submissions_team_id_assessment_id_unique_index
      )
    )
  end

  def down do
    drop(constraint(:submissions, :submissions_team_id_assessment_id_unique_index))
  end
end
