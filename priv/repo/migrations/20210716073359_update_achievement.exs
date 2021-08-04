defmodule Cadet.Repo.Migrations.UpdateAchievement do
  use Ecto.Migration
  import Ecto.Query, only: [from: 2]

  def change do
    alter table(:achievements) do
      add(:course_id, references(:courses), null: true)
    end

    alter table(:goals) do
      add(:course_id, references(:courses), null: true)
    end

    alter table(:goal_progress) do
      add(:course_reg_id, references(:course_registrations), null: true)
    end

    execute(fn ->
      courses = from(c in "courses", select: c.id) |> repo().all()
      course_id = courses |> Enum.at(0)
      repo().update_all("achievements", set: [course_id: course_id])
      repo().update_all("goals", set: [course_id: course_id])
    end)

    execute(
      "update goal_progress gp set course_reg_id = (select cr.id from course_registrations cr where cr.user_id = gp.user_id)"
    )

    alter table(:achievements) do
      modify(:course_id, references(:courses), null: false, from: references(:courses))
    end

    alter table(:goals) do
      modify(:course_id, references(:courses), null: false, from: references(:courses))
    end

    alter table(:goal_progress) do
      remove(:user_id)

      modify(:course_reg_id, references(:course_registrations),
        null: false,
        from: references(:course_registrations)
      )
    end
  end
end
