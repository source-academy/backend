defmodule Cadet.Repo.Migrations.AddFeedbackUrlToCourses do
  use Ecto.Migration

  def up do
    alter table(:courses) do
      add(:feedback_url, :string, null: true)
    end
  end

  def down do
    alter table(:courses) do
      remove(:feedback_url)
    end
  end
end
