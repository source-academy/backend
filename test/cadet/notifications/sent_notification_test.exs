defmodule Cadet.Notifications.SentNotificationTest do
  alias Cadet.Notifications.SentNotification
  alias Cadet.Repo

  use Cadet.ChangesetCase, entity: SentNotification

  setup do
    course = insert(:course)
    student = insert(:course_registration, %{course: course, role: :student})

    changeset =
      SentNotification.changeset(%SentNotification{}, %{
        content: "Test Content 1",
        course_reg_id: student.id
      })

    {:ok, _sent_notification1} = Repo.insert(changeset)

    {:ok,
     %{
       changeset: changeset,
       course: course,
       student: student
     }}
  end

  describe "Changesets" do
    test "valid changesets", %{
      student: student
    } do
      assert_changeset(
        %{
          content: "Test Content 2",
          course_reg_id: student.id
        },
        :valid
      )
    end

    test "invalid changesets missing content", %{
      student: student
    } do
      assert_changeset(
        %{
          course_reg_id: student.id
        },
        :invalid
      )
    end

    test "invalid changesets missing course_reg_id" do
      assert_changeset(
        %{
          content: "Test Content 2"
        },
        :invalid
      )
    end

    test "invalid changeset foreign key constraint", %{
      student: student
    } do
      changeset =
        SentNotification.changeset(%SentNotification{}, %{
          content: "Test Content 2",
          course_reg_id: student.id + 1000
        })

      {:error, changeset} = Repo.insert(changeset)

      assert changeset.errors == [
               course_reg_id:
                 {"does not exist",
                  [
                    constraint: :foreign,
                    constraint_name: "sent_notifications_course_reg_id_fkey"
                  ]}
             ]
    end
  end
end
