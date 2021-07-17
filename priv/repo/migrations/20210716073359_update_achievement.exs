defmodule Cadet.Repo.Migrations.UpdateAchievement do
  use Ecto.Migration

  def change do
    alter table(:achievements) do
      add(:course_id, references(:courses), null: false)
    end

    alter table(:goals) do
      add(:course_id, references(:courses), null: false)
    end

    alter table(:goal_progress) do
      remove(:user_id)
      add(:course_reg_id, references(:course_registrations))
    end
  end
end
