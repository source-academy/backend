defmodule Cadet.Repo.Migrations.DropGroupNameConstraint do
  use Ecto.Migration

  def change do
    drop(unique_index(:groups, [:name]))
    drop(unique_index(:groups, [:name, :course_id]))
    create(unique_index(:groups, [:name, :course_id], name: :unique_name_per_course))
  end
end
