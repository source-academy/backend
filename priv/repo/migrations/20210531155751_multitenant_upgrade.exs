defmodule Cadet.Repo.Migrations.MultitenantUpgrade do
  use Ecto.Migration
  import Ecto.Query

  def change do
    # Tracks course configurations
    create table(:courses) do
      add(:course_name, :string, null: false)
      add(:course_short_name, :string)
      add(:viewable, :boolean, null: false, default: true)
      add(:enable_game, :boolean, null: false, default: true)
      add(:enable_achievements, :boolean, null: false, default: true)
      add(:enable_sourcecast, :boolean, null: false, default: true)
      add(:source_chapter, :integer, null: false)
      add(:source_variant, :string, null: false)
      add(:module_help_text, :string)
      timestamps()
    end

    # Tracks assessment configurations per assessment type in a course
    create table(:assessment_configs) do
      add(:order, :integer, null: true)
      add(:type, :string, null: false)
      add(:course_id, references(:courses), null: false)
      add(:show_grading_summary, :boolean, null: false, default: true)
      add(:is_manually_graded, :boolean, null: false, default: true)
      add(:early_submission_xp, :integer, null: false)
      add(:hours_before_early_xp_decay, :integer, null: false)
      timestamps()
    end

    # Tracks course registrations (many-to-many r/s between users and courses)
    create table(:course_registrations) do
      add(:role, :role, null: false)
      add(:game_states, :map, default: %{})
      add(:group_id, references(:groups))
      add(:user_id, references(:users), null: false)
      add(:course_id, references(:courses), null: false)
      timestamps()
    end

    # Enforce that users cannot be enrolled twice in a course
    create(
      unique_index(:course_registrations, [:user_id, :course_id],
        name: :course_registrations_user_id_course_id_index
      )
    )

    # latest_viewed_id to track which course to load after the user logs in.
    # name and username modifications to allow for names to be nullable as accounts can
    #   now be precreated by any course instructor by specifying the username used in the
    #   respective auth provider.
    alter table(:users) do
      add(:latest_viewed_id, references(:courses), null: true)
      modify(:name, :string, null: true)
      modify(:username, :string, null: false)
    end

    # Prep for migration of leader_id from User entity to CourseRegistration entity.
    # Also make groups associated with a course.
    rename(table(:groups), :leader_id, to: :temp_leader_id)
    drop(constraint(:groups, "groups_leader_id_fkey"))
    drop(constraint(:groups, "groups_mentor_id_fkey"))

    alter table(:groups) do
      remove(:mentor_id)
      add(:leader_id, references(:course_registrations), null: true)
      add(:course_id, references(:courses))
    end

    # Make assessments related to an assessment config and a course
    alter table(:assessments) do
      add(:config_id, references(:assessment_configs))
      add(:course_id, references(:courses))
    end

    drop(unique_index(:assessments, [:number]))
    create(unique_index(:assessments, [:number, :course_id]))

    # Prep for migration of student_id and unsubmitted_by_id from User entity to CourseRegistration entity.
    rename(table(:submissions), :student_id, to: :temp_student_id)
    rename(table(:submissions), :unsubmitted_by_id, to: :temp_unsubmitted_by_id)
    drop(constraint(:submissions, "submissions_student_id_fkey"))
    drop(constraint(:submissions, "submissions_unsubmitted_by_id_fkey"))

    alter table(:submissions) do
      add(:student_id, references(:course_registrations))
      add(:unsubmitted_by_id, references(:course_registrations))
    end

    alter table(:submission_votes) do
      add(:voter_id, references(:course_registrations))
    end

    rename(table(:answers), :grader_id, to: :temp_grader_id)
    drop(constraint(:answers, "answers_grader_id_fkey"))

    # Remove grade metric from backend
    alter table(:answers) do
      remove(:grade)
      remove(:adjustment)
      add(:grader_id, references(:course_registrations), null: true)
    end

    alter table(:questions) do
      remove(:max_grade)
      add(:show_solution, :boolean, null: false, default: false)
      add(:build_hidden_testcases, :boolean, null: false, default: false)
      add(:blocking, :boolean, null: false, default: false)
    end

    # Update notifications
    alter table(:notifications) do
      add(:course_reg_id, references(:course_registrations))
    end

    # Sourcecasts to be associated with a course
    alter table(:sourcecasts) do
      add(:course_id, references(:courses))
    end

    # Stories to be associated with a course
    alter table(:stories) do
      add(:course_id, references(:courses))
    end

    # Sublanguage is now being tracked under course configuration, and can be different depending on course
    drop_if_exists(table(:sublanguages))

    # Manual data entry and manipulation to migrate data from Source Academy Knight --> Rook.
    # Note that in Knight, there was only 1 course running at a time, so it is okay to assume
    # that all existing data belongs to that course.
    execute(
      fn ->
        # Create the new course for migration
        {1, [course | _]} =
          repo().insert_all(
            "courses",
            [
              %{
                course_name: "CS1101S Programming Methodology (AY21/22 Sem 1)",
                course_short_name: "CS1101S",
                viewable: true,
                enable_game: true,
                enable_achievements: true,
                enable_sourcecast: true,
                source_chapter: 1,
                source_variant: "default",
                inserted_at: Timex.now(),
                updated_at: Timex.now()
              }
            ],
            returning: [:id]
          )

        # Namespace existing usernames
        from(u in "users", update: [set: [username: fragment("? || ? ", "luminus/", u.username)]])
        |> repo().update_all([])

        # Create course registrations for existing users
        from(u in "users",
          select: %{
            user_id: u.id,
            role: u.role,
            group_id: u.group_id,
            game_states: u.game_states
          }
        )
        |> repo().all()
        |> Enum.map(fn user ->
          Map.merge(user, %{
            course_id: course.id,
            inserted_at: Timex.now(),
            updated_at: Timex.now()
          })
        end)
        |> (&repo().insert_all("course_registrations", &1)).()

        # Add latest_viewed_id to existing users
        repo().update_all("users", set: [latest_viewed_id: course.id])

        # Handle groups, adding course_id
        repo().update_all("groups", set: [course_id: course.id])

        # Update existing Path questions with new question config
        # The questions from other assessment types are not updated as these fields default to false
        from(q in "questions",
          join: a in "assessments",
          on: a.id == q.assessment_id,
          where: a.type == "path"
        )
        |> repo().update_all(
          set: [
            show_solution: true,
            build_hidden_testcases: true,
            blocking: true
          ]
        )

        # Create Assessment Configurations based on Source Academy Knight
        {5, configs} =
          ["Missions", "Quests", "Paths", "Contests", "Others"]
          |> Enum.with_index(1)
          |> Enum.map(fn {assessment_type, idx} ->
            %{
              order: idx,
              type: assessment_type,
              course_id: course.id,
              show_grading_summary: assessment_type in ["Missions", "Quests"],
              is_manually_graded: assessment_type != "Paths",
              early_submission_xp: 100,
              hours_before_early_xp_decay: 24,
              inserted_at: Timex.now(),
              updated_at: Timex.now()
            }
          end)
          |> (&repo().insert_all("assessment_configs", &1, returning: [:id])).()

        # assessment_configs = repo().insert_all("assessment_configs", configs, returning: [:id])

        # Link existing assessments to an assessment config and course
        [
          {"mission", "Missions"},
          {"sidequest", "Quests"},
          {"path", "Paths"},
          {"contest", "Contests"},
          {"practical", "Others"}
        ]
        |> Enum.each(fn {old_type, new_type} ->
          config_id =
            from(ac in "assessment_configs", where: ac.type == ^new_type, select: ac.id)
            |> repo().all()
            |> Enum.at(0)

          from(a in "assessments", where: a.type == ^old_type)
          |> repo().update_all(
            set: [
              config_id: config_id,
              course_id: course.id
            ]
          )
        end)

        # Updating student_id and unsubmitted_by_id from User to CourseRegistration
        from(
          s in "submissions",
          join: st in "course_registrations",
          on: st.user_id == s.temp_student_id,
          update: [set: [student_id: st.id]]
        )
        |> repo().update_all([])

        from(
          s in "submissions",
          join: cr in "course_registrations",
          on: cr.user_id == s.temp_unsubmitted_by_id,
          update: [set: [unsubmitted_by_id: cr.id]]
        )
        |> repo().update_all([])

        # Updating grader_id in answer from User to CourseRegistration
        from(
          a in "answers",
          join: cr in "course_registrations",
          on: cr.user_id == a.temp_grader_id,
          update: [set: [grader_id: cr.id]]
        )
        |> repo().update_all([])

        # Updating user_id to voter_id of CourseRegistration
        from(
          s in "submission_votes",
          join: cr in "course_registrations",
          on: cr.user_id == s.user_id,
          update: [set: [voter_id: cr.id]]
        )
        |> repo().update_all([])

        # Updating user_id to course_reg_id in Notification
        from(
          n in "notifications",
          join: cr in "course_registrations",
          on: cr.user_id == n.user_id,
          update: [set: [course_reg_id: cr.id]]
        )
        |> repo().update_all([])

        # Add course id to all Sourcecasts
        repo().update_all("sourcecasts", set: [course_id: course.id])

        # Add course id to all Stories
        repo().update_all("stories", set: [course_id: course.id])
      end,
      fn -> nil end
    )

    # Update leader_id to course registrations)
    execute(
      "update groups g set leader_id = coalesce((select cr.id from course_registrations cr where cr.user_id = g.temp_leader_id), (select cr.id from course_registrations cr where cr.role = 'staff' or cr.role = 'admin'))"
    )

    # Cleanup users table after data migration
    alter table(:users) do
      remove(:role)
      remove(:group_id)
      remove(:game_states)
    end

    # Cleanup groups table, and make course_id and leader_id non-nullable
    alter table(:groups) do
      remove(:temp_leader_id)

      modify(:course_id, references(:courses), null: false, from: references(:courses))
    end

    create(unique_index(:groups, [:name, :course_id]))

    # Cleanup assessments table, and make config_id and course_id non-nullable
    alter table(:assessments) do
      remove(:type)
      modify(:config_id, references(:assessment_configs), null: false, from: references(:courses))
      modify(:course_id, references(:courses), null: false, from: references(:courses))
    end

    alter table(:submissions) do
      remove(:temp_student_id)
      remove(:temp_unsubmitted_by_id)

      modify(:student_id, references(:course_registrations),
        null: false,
        from: references(:course_registrations)
      )
    end

    alter table(:answers) do
      remove(:temp_grader_id)
    end

    create(index(:submissions, :student_id))
    create(unique_index(:submissions, [:assessment_id, :student_id]))

    alter table(:submission_votes) do
      remove(:user_id)

      modify(:voter_id, references(:course_registrations),
        null: false,
        from: references(:course_registrations)
      )
    end

    create(unique_index(:submission_votes, [:voter_id, :question_id, :rank], name: :unique_score))

    alter table(:notifications) do
      remove(:user_id)

      modify(:course_reg_id, references(:course_registrations),
        null: false,
        from: references(:course_registrations)
      )
    end

    # Set course_id to be non-nullable
    alter table(:stories) do
      modify(:course_id, references(:courses), null: false, from: references(:courses))
    end
  end
end
