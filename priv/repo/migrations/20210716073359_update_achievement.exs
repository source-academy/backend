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

    execute(
      fn ->
        courses = from(c in "courses", select: {c.id}) |> repo().all()
        course_id = courses |> Enum.at(0) |> elem(0)
        repo().update_all("achievements", set: [course_id: course_id])
        repo().update_all("goals", set: [course_id: course_id])
        repo().delete_all("goal_progress")
      end
    )
  end
end
