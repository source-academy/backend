defmodule Cadet.Repo.Migrations.AddIndexOnStudentIdInSubmission do
  use Ecto.Migration

  def change do
    create(index(:submissions, :student_id))
  end
end
