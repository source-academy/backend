defmodule Cadet.Notifications.NotificationPreferenceTest do
  alias Cadet.Notifications.NotificationPreference

  use Cadet.ChangesetCase, entity: NotificationPreference

  setup do
    course1 = insert(:course, %{course_short_name: "course 1"})
    config1 = insert(:assessment_config, %{course: course1})

    student_user = insert(:user)
    avenger_user = insert(:user)
    avenger = insert(:course_registration, %{user: avenger_user, course: course1, role: :staff})
    student = insert(:course_registration, %{user: student_user, course: course1, role: :student})

    noti_type1 = insert(:notification_type, %{name: "Notification Type 1"})

    noti_config1 =
      insert(:notification_config, %{
        notification_type: noti_type1,
        course: course1,
        assessment_config: config1
      })

    time_option1 =
      insert(:time_option, %{
        notification_config: noti_config1
      })

    {:ok,
     %{
       course1: course1,
       config1: config1,
       student: student,
       avenger: avenger,
       noti_type1: noti_type1,
       noti_config1: noti_config1,
       time_option1: time_option1
     }}
  end

  describe "Changesets" do
    test "valid changesets", %{
      student: student,
      avenger: avenger,
      noti_config1: noti_config1,
      time_option1: time_option1
    } do
      assert_changeset(
        %{
          is_enabled: false,
          notification_config_id: noti_config1.id,
          time_option_id: time_option1.id,
          course_reg_id: student.id
        },
        :valid
      )

      assert_changeset(
        %{
          is_enabled: false,
          notification_config_id: noti_config1.id,
          time_option_id: time_option1.id,
          course_reg_id: avenger.id
        },
        :valid
      )
    end

    test "invalid changesets missing notification config", %{
      avenger: avenger,
      time_option1: time_option1
    } do
      assert_changeset(
        %{
          is_enabled: false,
          notification_config_id: nil,
          time_option_id: time_option1.id,
          course_reg_id: avenger.id
        },
        :invalid
      )
    end

    test "invalid changesets missing course registration", %{
      noti_config1: noti_config1,
      time_option1: time_option1
    } do
      assert_changeset(
        %{
          is_enabled: false,
          notification_config_id: noti_config1.id,
          time_option_id: time_option1.id,
          course_reg_id: nil
        },
        :invalid
      )
    end
  end
end
