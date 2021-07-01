defmodule Cadet.Repo.Migrations.MultitenantUpgrade do
  use Ecto.Migration
  import Ecto.Query, only: [from: 2, where: 2]

  alias Cadet.Accounts.{CourseRegistration, Notification, Role, User}
  alias Cadet.Assessments.{Assessment, Submission, SubmissionVotes}
  alias Cadet.Courses.{AssessmentConfig, Course, Group, Sourcecast}
  alias Cadet.Repo
  alias Cadet.Stories.Story

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
      add(:build_solution, :boolean, null: false, default: false)
      add(:is_contest, :boolean, null: false, default: false)
      add(:build_hidden, :boolean, null: false, default: false)
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

    # Prep for migration of leader_id and mentor_id from User entity to CourseRegistration entity.
    # Also make groups associated with a course.
    rename(table(:groups), :leader_id, to: :temp_leader_id)
    rename(table(:groups), :mentor_id, to: :temp_mentor_id)
    drop(constraint(:groups, "groups_leader_id_fkey"))
    drop(constraint(:groups, "groups_mentor_id_fkey"))

    alter table(:groups) do
      add(:leader_id, references(:course_registrations))
      add(:mentor_id, references(:course_registrations))
      add(:course_id, references(:courses))
    end

    # Make assessments related to an assessment config and a course
    alter table(:assessments) do
      add(:config_id, references(:assessment_configs))
      add(:course_id, references(:courses))
    end

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

    # Remove grade metric from backend
    alter table(:answers) do
      remove(:grade)
      remove(:adjustment)
      remove(:grader_id)
      add(:grader_id, references(:course_registrations), null: true)
    end

    alter table(:questions) do
      remove(:max_grade)
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
        {:ok, course} =
          %Course{}
          |> Course.changeset(%{
            course_name: "CS1101S Programming Methodology (AY21/22 Sem 1)",
            course_short_name: "CS1101S",
            viewable: true,
            enable_game: true,
            enable_achievments: true,
            enable_sourcecast: true,
            source_chapter: 1,
            source_variant: "default"
          })
          |> Repo.insert()

        # Create course registrations for existing users
        from(u in "users", select: {u.id, u.role, u.group_id, u.game_states})
        |> Repo.all()
        |> Enum.each(fn user ->
          %CourseRegistration{}
          |> CourseRegistration.changeset(%{
            user_id: elem(user, 0),
            role: elem(user, 1),
            group_id: elem(user, 2),
            game_states: elem(user, 3),
            course_id: course.id
          })
          |> Repo.insert()
        end)

        # Add latest_viewed_id to existing users
        User
        |> Repo.all()
        |> Enum.each(fn user ->
          user
          |> User.changeset(%{latest_viewed_id: course.id})
          |> Repo.update()
        end)

        # Handle groups (adding course_id, and updating leader_id and mentor_id to course registrations)
        from(g in "groups", select: {g.id, g.temp_leader_id, g.temp_mentor_id})
        |> Repo.all()
        |> Enum.each(fn group ->
          leader_id =
            case elem(group, 1) do
              # leader_id is now going to be non-nullable. if it was previously nil, we will just
              # assign a staff to be the leader_id during migration
              nil ->
                CourseRegistration
                |> where(role: :staff)
                |> Repo.one()

                Map.fetch!(:id)

              id ->
                CourseRegistration
                |> where(user_id: ^id)
                |> Repo.one()
                |> Map.fetch!(:id)
            end

          mentor_id =
            case elem(group, 2) do
              nil ->
                nil

              id ->
                CourseRegistration
                |> where(user_id: ^id)
                |> Repo.one()
                |> Map.fetch!(:id)
            end

          Group
          |> where(id: ^elem(group, 0))
          |> Repo.one()
          |> Group.changeset(%{leader_id: leader_id, mentor_id: mentor_id, course_id: course.id})
          |> Repo.update()
        end)

        # Create Assessment Configurations based on Source Academy Knight
        ["Missions", "Quests", "Paths", "Contests", "Others"]
        |> Enum.each(fn assessment_type ->
          %AssessmentConfig{}
          |> AssessmentConfig.changeset(%{
            type: assessment_type,
            course_id: course.id,
            build_solution: assessment_type in ["Paths", "Others"],
            build_hidden: assessment_type == "Paths",
            is_contest: assessment_type == "Contests",
            early_submission_xp: 200,
            hours_before_early_xp_decay: 48
          })
          |> Repo.insert()
        end)

        # Link existing assessments to an assessment config and course
        from(a in "assessments", select: {a.id, a.type})
        |> Repo.all()
        |> Enum.each(fn assessment ->
          assessment_type =
            case elem(assessment, 1) do
              "mission" -> "Missions"
              "sidequest" -> "Quests"
              "path" -> "Paths"
              "contest" -> "Contests"
              "practical" -> "Others"
            end

          assessment_config =
            AssessmentConfig
            |> where(type: ^assessment_type)
            |> Repo.one()

          Assessment
          |> where(id: ^elem(assessment, 0))
          |> Repo.one()
          |> Assessment.changeset(%{config_id: assessment_config.id, course_id: course.id})
          |> Repo.update()
        end)

        # Updating student_id and unsubmitted_by_id from User to CourseRegistration
        from(s in "submissions", select: {s.id, s.temp_student_id, s.temp_unsubmitted_by_id})
        |> Repo.all()
        |> Enum.each(fn submission ->
          student_id =
            CourseRegistration
            |> where(user_id: ^elem(submission, 1))
            |> Repo.one()
            |> Map.fetch!(:id)

          unsubmitted_by_id =
            case elem(submission, 2) do
              nil ->
                nil

              id ->
                CourseRegistration
                |> where(user_id: ^id)
                |> Repo.one()
                |> Map.fetch!(:id)
            end

          Submission
          |> where(id: ^elem(submission, 0))
          |> Repo.one()
          |> Submission.changeset(%{student_id: student_id, unsubmitted_by_id: unsubmitted_by_id})
          |> Repo.update()
        end)

        from(s in "submission_votes", select: {s.id, s.user_id})
        |> Repo.all()
        |> Enum.each(fn vote ->
          voter_id =
            CourseRegistration
            |> where(user_id: ^elem(vote, 1))
            |> Repo.one()
            |> Map.fetch!(:id)

          SubmissionVotes
          |> where(id: ^elem(vote, 0))
          |> Repo.one()
          |> SubmissionVotes.changeset(%{voter_id: voter_id})
          |> Repo.update()
        end)

        from(n in "notifications", select: {n.id, n.user_id})
        |> Repo.all()
        |> Enum.each(fn notification ->
          course_reg_id =
            CourseRegistration
            |> where(user_id: ^elem(notification, 1))
            |> Repo.one()
            |> Map.fetch!(:id)

          Notification
          |> where(id: ^elem(notification, 0))
          |> Repo.one()
          |> Notification.changeset(%{course_reg_id: course_reg_id})
          |> Repo.update()
        end)

        # Add course id to all Sourcecasts
        Sourcecast
        |> Repo.all()
        |> Enum.each(fn x ->
          x
          |> Sourcecast.changeset(%{course_id: course.id})
          |> Repo.update()
        end)

        # Add course id to all Stories
        Story
        |> Repo.all()
        |> Enum.each(fn x ->
          x
          |> Story.changeset(%{course_id: course.id})
          |> Repo.update()
        end)
      end,
      fn -> nil end
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
      remove(:temp_mentor_id)

      modify(:leader_id, references(:course_registrations),
        null: false,
        from: references(:course_registrations)
      )

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
