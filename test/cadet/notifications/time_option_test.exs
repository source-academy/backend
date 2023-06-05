defmodule Cadet.Notifications.TimeOptionTest do
  alias Cadet.Notifications.TimeOption

  use Cadet.ChangesetCase, entity: TimeOption

  setup do
    course1 = insert(:course, %{course_short_name: "course 1"})

    config1 = insert(:assessment_config, %{course: course1})

    noti_type1 = insert(:notification_type, %{name: "Notification Type 1"})

    noti_config1 =
      insert(:notification_config, %{
        notification_type: noti_type1,
        course: course1,
        assessment_config: config1
      })

    changeset =
      TimeOption.changeset(%TimeOption{}, %{
        minutes: 10,
        is_default: true,
        notification_config_id: noti_config1.id
      })

    {:ok, _time_option1} = Repo.insert(changeset)

    {:ok,
     %{
       noti_config1: noti_config1,
       changeset: changeset
     }}
  end

  describe "Changesets" do
    test "valid changesets", %{noti_config1: noti_config1} do
      assert_changeset(
        %{
          minutes: 20,
          is_default: false,
          notification_config_id: noti_config1.id
        },
        :valid
      )
    end

    test "invalid changesets missing minutes" do
      assert_changeset(
        %{
          is_default: false,
          notification_config_id: 2
        },
        :invalid
      )
    end

    test "invalid changesets missing notification_config_id" do
      assert_changeset(
        %{
          minutes: 2,
          is_default: false
        },
        :invalid
      )
    end

    test "invalid changeset duplicate minutes", %{changeset: changeset} do
      {:error, changeset} = Repo.insert(changeset)

      assert changeset.errors == [
               minutes:
                 {"has already been taken",
                  [constraint: :unique, constraint_name: "unique_time_options"]}
             ]
    end

    test "invalid notification_config_id", %{noti_config1: noti_config1} do
      changeset =
        TimeOption.changeset(%TimeOption{}, %{
          minutes: 10,
          is_default: true,
          notification_config_id: noti_config1.id + 1000
        })

      {:error, changeset} = Repo.insert(changeset)

      assert changeset.errors == [
               notification_config_id:
                 {"does not exist",
                  [
                    constraint: :foreign,
                    constraint_name: "time_options_notification_config_id_fkey"
                  ]}
             ]
    end
  end
end
