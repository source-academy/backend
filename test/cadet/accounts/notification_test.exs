defmodule Cadet.Accounts.NotificationTest do
  alias Cadet.Accounts.Notification

  use Cadet.ChangesetCase, entity: Notification

  @required_fields ~w(type role user_id)a

  setup do
    assessment = insert(:assessment, %{is_published: true})
    avenger = insert(:user, %{role: :staff})
    student = insert(:user, %{role: :student})
    submission = insert(:submission, %{student: student, assessment: assessment})

    valid_params_for_student = %{
      type: :new,
      read: false,
      role: student.role,
      user_id: student.id,
      assessment_id: assessment.id
    }

    valid_params_for_avenger = %{
      type: :submitted,
      read: false,
      role: avenger.role,
      user_id: avenger.id,
      submission_id: submission.id
    }

    {:ok,
     %{
       assessment: assessment,
       avenger: avenger,
       student: student,
       submission: submission,
       valid_params_for_student: valid_params_for_student,
       valid_params_for_avenger: valid_params_for_avenger
     }}
  end

  describe "changeset" do
    test "valid notification params for student", %{valid_params_for_student: params} do
      assert_changeset(params, :valid)
    end

    test "valid notification params for avenger", %{valid_params_for_avenger: params} do
      assert_changeset(params, :valid)
    end

    test "valid notification params with question id", %{valid_params_for_student: params} do
      params = Map.put(params, :question_id, 12_345)

      assert_changeset(params, :valid)
    end

    test "invalid changeset missing required params for student", %{
      valid_params_for_student: params
    } do
      for field <- @required_fields ++ [:assessment_id] do
        params_missing_field = Map.delete(params, field)

        assert_changeset(params_missing_field, :invalid)
      end
    end

    test "invalid changeset missing required params for avenger", %{
      valid_params_for_avenger: params
    } do
      for field <- @required_fields ++ [:submission_id] do
        params_missing_field = Map.delete(params, field)

        assert_changeset(params_missing_field, :invalid)
      end
    end

    test "invalid role", %{valid_params_for_avenger: params} do
      params = Map.put(params, :role, :admin)

      assert_changeset(params, :invalid)
    end
  end

  describe "repo" do
    test "fetch notifications when there are none", %{avenger: avenger, student: student} do
      {:ok, notifications_avenger} = Notification.fetch(avenger)
      {:ok, notifications_student} = Notification.fetch(student)

      assert notifications_avenger == []
      assert notifications_student == []
    end

    test "fetch notifications when all unread", %{assessment: assessment, student: student} do
      notifications =
        insert_list(3, :notification, %{
          read: false,
          assessment_id: assessment.id,
          user_id: student.id
        })

      expected = Enum.sort(notifications, &(&1.id < &2.id))

      {:ok, notifications_db} = Notification.fetch(student)

      results = Enum.sort(notifications_db, &(&1.id < &2.id))

      assert results == expected
    end

    test "fetch notifications when all read", %{assessment: assessment, student: student} do
      insert_list(3, :notification, %{
        read: true,
        assessment_id: assessment.id,
        user_id: student.id
      })

      {:ok, notifications_db} = Notification.fetch(student)

      assert notifications_db == []
    end

    test "write notification valid params", %{
      assessment: assessment,
      avenger: avenger,
      student: student,
      submission: submission
    } do
      params_student = %{
        type: :new,
        read: false,
        role: student.role,
        user_id: student.id,
        assessment_id: assessment.id
      }

      params_avenger = %{
        type: :submitted,
        read: false,
        role: avenger.role,
        user_id: avenger.id,
        submission_id: submission.id
      }

      assert {:ok, _} = Notification.write(params_student)
      assert {:ok, _} = Notification.write(params_avenger)
    end

    test "write notification missing params", %{
      assessment: assessment,
      student: student
    } do
      params_student = %{
        type: :new,
        read: false,
        role: student.role,
        user_id: student.id,
        assessment_id: assessment.id
      }

      for field <- @required_fields do
        params = Map.delete(params_student, field)

        {:error, changeset} = Notification.write(params)

        assert changeset.valid? == false
      end
    end

    test "acknowledge notification valid user", %{
      assessment: assessment,
      student: student
    } do
      notification =
        insert(:notification, %{
          read: false,
          assessment_id: assessment.id,
          user_id: student.id
        })

      {:ok, notification_db} = Notification.acknowledge(notification.id, student)

      assert %{read: true} = notification_db
    end

    test "acknowledge notification invalid user", %{
      assessment: assessment,
      avenger: avenger,
      student: student
    } do
      notification =
        insert(:notification, %{
          read: false,
          assessment_id: assessment.id,
          user_id: student.id
        })

      assert {:error, _} = Notification.acknowledge(notification.id, avenger)
    end

    test "handle unsubmit works properly", %{
      assessment: assessment,
      student: student
    } do
      {:ok, notification_db} = Notification.handle_unsubmit_notifications(assessment.id, student)

      assert %{type: :unsubmitted} = notification_db
    end

    test "receives notification when submitted" do
      assessment = insert(:assessment, %{is_published: true})
      avenger = insert(:user, %{role: :staff})
      group = insert(:group, %{leader: avenger})
      student = insert(:user, %{role: :student, group: group})
      submission = insert(:submission, %{student: student, assessment: assessment})

      Notification.write_notification_when_student_submits(submission)

      notification =
        Repo.get_by(Notification,
          user_id: avenger.id,
          type: :submitted,
          submission_id: submission.id
        )

      assert %{type: :submitted} = notification
    end

    test "receives notification when autograded", %{
      assessment: assessment,
      student: student,
      submission: submission
    } do
      Notification.write_notification_when_graded(submission.id, :autograded)

      notification =
        Repo.get_by(Notification,
          user_id: student.id,
          type: :autograded,
          assessment_id: assessment.id
        )

      assert %{type: :autograded} = notification
    end

    test "receives notification when manually graded", %{
      assessment: assessment,
      student: student,
      submission: submission
    } do
      Notification.write_notification_when_graded(submission.id, :graded)

      notification =
        Repo.get_by(Notification, user_id: student.id, type: :graded, assessment_id: assessment.id)

      assert %{type: :graded} = notification
    end

    test "every student receives notifications when a new assessment is published", %{
      assessment: assessment,
      student: student
    } do
      students = [student | insert_list(3, :user, %{role: :student})]

      Notification.write_notification_for_new_assessment(assessment.id)

      for student <- students do
        notification =
          Repo.get_by(Notification, user_id: student.id, type: :new, assessment_id: assessment.id)

        assert %{type: :new} = notification
      end
    end
  end
end
