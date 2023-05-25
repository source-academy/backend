defmodule Cadet.Notifications.NotificationConfigTest do
  alias Cadet.Notifications.NotificationConfig

  use Cadet.ChangesetCase, entity: NotificationConfig

  setup do
    course1 = insert(:course, %{course_short_name: "course 1"})
    course2 = insert(:course, %{course_short_name: "course 2"})
    config1 = insert(:assessment_config, %{course: course1})

    noti_type1 = insert(:notification_type, %{name: "Notification Type 1"})
    noti_type2 = insert(:notification_type, %{name: "Notification Type 2"})

    {:ok,
     %{
       course1: course1,
       course2: course2,
       config1: config1,
       noti_type1: noti_type1,
       noti_type2: noti_type2
     }}
  end

  describe "Changesets" do
    test "valid changesets", %{
      course1: course1,
      course2: course2,
      config1: config1,
      noti_type1: noti_type1,
      noti_type2: noti_type2
    } do
      assert_changeset(
        %{
          notification_type_id: noti_type1.id,
          course_id: course1.id,
          config_id: config1.id
        },
        :valid
      )

      assert_changeset(
        %{
          notification_type_id: noti_type2.id,
          course_id: course2.id,
          config_id: nil
        },
        :valid
      )
    end

    test "invalid changesets missing notification type" do
      assert_changeset(
        %{
          notification_type_id: nil,
          course_id: nil,
          config_id: nil
        },
        :invalid
      )
    end

    test "invalid changesets missing course", %{
      noti_type1: noti_type1
    } do
      assert_changeset(
        %{
          notification_type_id: noti_type1.id,
          course_id: nil,
          config_id: nil
        },
        :invalid
      )
    end
  end
end
