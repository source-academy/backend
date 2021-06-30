defmodule Cadet.Repo.Migrations.AddCourseConfiguration do
  use Ecto.Migration
  import Ecto.Query, only: [from: 2, where: 2]

  alias Cadet.Accounts.{CourseRegistration, Role, User}
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
      add(:is_graded, :boolean, null: false)
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

        # Create Assessment Configurations based on Source Academy Knight
        ["Missions", "Quests", "Paths", "Contests", "Others"]
        |> Enum.each(fn assessment_type ->
          %AssessmentConfig{}
          |> AssessmentConfig.changeset(%{
            type: assessment_type,
            course_id: course.id,
            is_graded: true,
            early_submission_xp: 200,
            hours_before_early_xp_decay: 48
          })
          |> Repo.insert()

          # TODO: Link these to the new assessments/ submissions/ answers when they are done
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

    # Set course_id to be non-nullable
    alter table(:stories) do
      modify(:course_id, references(:courses), null: false, from: references(:courses))
    end
  end
end
