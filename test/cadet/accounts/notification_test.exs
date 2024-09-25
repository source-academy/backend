defmodule Cadet.Accounts.NotificationTest do
  alias Cadet.Accounts.{Notification, Notifications, TeamMember}

  use Cadet.ChangesetCase, entity: Notification

  @required_fields ~w(type course_reg_id)a

  setup do
    assessment = insert(:assessment, %{is_published: true})
    avenger_user = insert(:user)
    student_user = insert(:user)
    avenger = insert(:course_registration, %{user: avenger_user, role: :staff})
    student = insert(:course_registration, %{user: student_user, role: :student})
    individual_submission = insert(:submission, %{student: student, assessment: assessment})

    team = insert(:team)
    insert(:team_member, %{team: team})
    insert(:team_member, %{team: team})
    team_submission = insert(:submission, %{team: team, assessment: assessment, student: nil})

    valid_params_for_student = %{
      type: :new,
      read: false,
      role: student.role,
      course_reg_id: student.id,
      assessment_id: assessment.id
    }

    valid_params_for_avenger = %{
      type: :submitted,
      read: false,
      role: avenger.role,
      course_reg_id: avenger.id,
      assessment_id: assessment.id,
      submission_id: individual_submission.id
    }

    {:ok,
     %{
       assessment: assessment,
       avenger: avenger,
       student: student,
       team: team,
       individual_submission: individual_submission,
       team_submission: team_submission,
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

    test "invalid changeset missing required params for student", %{
      valid_params_for_student: params
    } do
      for field <- @required_fields ++ [:assessment_id] do
        params_missing_field = Map.delete(params, field)

        assert_changeset(params_missing_field, :invalid)
      end
    end
  end

  describe "repo" do
    test "fetch notifications when there are none", %{avenger: avenger, student: student} do
      {:ok, notifications_avenger} = Notifications.fetch(avenger)
      {:ok, notifications_student} = Notifications.fetch(student)

      assert notifications_avenger == []
      assert notifications_student == []
    end

    test "fetch notifications when all unread", %{assessment: assessment, student: student} do
      notifications =
        insert_list(3, :notification, %{
          read: false,
          assessment_id: assessment.id,
          assessment: assessment,
          course_reg_id: student.id
        })

      expected =
        notifications |> Enum.sort(&(&1.id < &2.id)) |> Enum.map(&Map.delete(&1, :assessment))

      {:ok, notifications_db} = Notifications.fetch(student)

      results =
        notifications_db |> Enum.sort(&(&1.id < &2.id)) |> Enum.map(&Map.delete(&1, :assessment))

      assert results == expected
    end

    test "fetch notifications when all read", %{assessment: assessment, student: student} do
      insert_list(3, :notification, %{
        read: true,
        assessment_id: assessment.id,
        course_reg_id: student.id
      })

      {:ok, notifications_db} = Notifications.fetch(student)

      assert notifications_db == []
    end

    test "write notification valid params", %{
      assessment: assessment,
      avenger: avenger,
      student: student,
      individual_submission: individual_submission
    } do
      params_student = %{
        type: :new,
        read: false,
        role: student.role,
        course_reg_id: student.id,
        assessment_id: assessment.id
      }

      params_avenger = %{
        type: :submitted,
        read: false,
        role: avenger.role,
        course_reg_id: avenger.id,
        assessment_id: assessment.id,
        submission_id: individual_submission.id
      }

      assert {:ok, _} = Notifications.write(params_student)
      assert {:ok, _} = Notifications.write(params_avenger)
    end

    test "write notification and ensure no duplicates", %{
      assessment: assessment,
      avenger: avenger,
      student: student,
      individual_submission: individual_submission
    } do
      params_student = %{
        type: :new,
        read: false,
        role: student.role,
        course_reg_id: student.id,
        assessment_id: assessment.id
      }

      params_avenger = %{
        type: :submitted,
        read: false,
        role: avenger.role,
        course_reg_id: avenger.id,
        assessment_id: assessment.id,
        submission_id: individual_submission.id
      }

      Notifications.write(params_student)
      Notifications.write(params_student)

      assert Repo.one(
               from(n in Notification,
                 where:
                   n.type == ^:new and n.course_reg_id == ^student.id and
                     n.assessment_id == ^assessment.id
               )
             )

      Notifications.write(params_avenger)
      Notifications.write(params_avenger)

      assert Repo.one(
               from(n in Notification,
                 where:
                   n.type == ^:submitted and n.course_reg_id == ^avenger.id and
                     n.submission_id == ^individual_submission.id
               )
             )
    end

    test "write notification missing params", %{
      assessment: assessment,
      student: student
    } do
      params_student = %{
        type: :new,
        read: false,
        role: student.role,
        course_reg_id: student.id,
        assessment_id: assessment.id
      }

      for field <- @required_fields do
        params = Map.delete(params_student, field)

        {:error, changeset} = Notifications.write(params)

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
          course_reg_id: student.id
        })

      Notifications.acknowledge([notification.id], student)

      notification_db = Repo.get_by(Notification, id: notification.id)

      assert %{read: true} = notification_db
    end

    test "acknowledge multiple notifications valid user", %{
      assessment: assessment,
      student: student
    } do
      notifications =
        insert_list(3, :notification, %{
          read: false,
          assessment_id: assessment.id,
          course_reg_id: student.id
        })

      notifications
      |> Enum.map(& &1.id)
      |> Notifications.acknowledge(student)

      for n <- notifications do
        assert %{read: true} = Repo.get_by(Notification, id: n.id)
      end
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
          course_reg_id: student.id
        })

      assert {:error, _} = Notifications.acknowledge(notification.id, avenger)
    end

    test "handle unsubmit works properly", %{
      assessment: assessment,
      student: student
    } do
      {:ok, notification_db} = Notifications.handle_unsubmit_notifications(assessment.id, student)

      assert %{type: :unsubmitted} = notification_db
    end

    test "receives notification when submitted" do
      assessment = insert(:assessment, %{is_published: true})
      avenger = insert(:course_registration, %{role: :staff})
      group = insert(:group, %{leader: avenger})
      student = insert(:course_registration, %{role: :student, group: group})
      submission = insert(:submission, %{student: student, assessment: assessment})

      Notifications.write_notification_when_student_submits(submission)

      notification =
        Repo.get_by(Notification,
          course_reg_id: avenger.id,
          type: :submitted,
          submission_id: submission.id
        )

      assert %{type: :submitted} = notification
    end

    test "receives notification when submitted [team submission]" do
      assessment = insert(:assessment, %{is_published: true})
      avenger = insert(:course_registration, %{role: :staff})
      group = insert(:group, %{leader: avenger})
      team = insert(:team)
      team_submission = insert(:submission, %{team: team, assessment: assessment, student: nil})

      Enum.each(1..2, fn _ ->
        student = insert(:course_registration, %{role: :student, group: group})
        insert(:team_member, %{team: team, student: student})
      end)

      Notifications.write_notification_when_student_submits(team_submission)

      team_members =
        Repo.all(from(tm in TeamMember, where: tm.team_id == ^team.id, preload: :student))

      students = Enum.map(team_members, & &1.student)

      Enum.each(students, fn student ->
        notification =
          Repo.get_by(Notification,
            course_reg_id: student.id,
            type: :submitted,
            submission_id: team_submission.id
          )

        assert notification == nil
      end)
    end

    test "receives notification when autograded", %{
      assessment: assessment,
      student: student,
      individual_submission: individual_submission
    } do
      Notifications.write_notification_when_published(
        individual_submission.id,
        :published_grading
      )

      notification =
        Repo.get_by(Notification,
          course_reg_id: student.id,
          type: :published_grading,
          assessment_id: assessment.id
        )

      assert %{type: :published_grading} = notification
    end

    test "no notification when no submission", %{
      assessment: assessment,
      student: student
    } do
      Notifications.write_notification_when_published(-1, :published_grading)

      notification =
        Repo.get_by(Notification,
          course_reg_id: student.id,
          type: :published_grading,
          assessment_id: assessment.id
        )

      assert notification == nil
    end

    test "receives notification when autograded [team submission]", %{
      assessment: assessment,
      team: team,
      team_submission: team_submission
    } do
      Notifications.write_notification_when_published(team_submission.id, :published_grading)

      team_members =
        Repo.all(from(tm in TeamMember, where: tm.team_id == ^team.id, preload: :student))

      students = Enum.map(team_members, & &1.student)

      Enum.each(students, fn student ->
        notification =
          Repo.get_by(Notification,
            course_reg_id: student.id,
            type: :published_grading,
            assessment_id: assessment.id
          )

        assert %{type: :published_grading} = notification
      end)
    end

    test "receives notification when manually graded", %{
      assessment: assessment,
      student: student,
      individual_submission: individual_submission
    } do
      Notifications.write_notification_when_published(
        individual_submission.id,
        :published_grading
      )

      notification =
        Repo.get_by(Notification,
          course_reg_id: student.id,
          type: :published_grading,
          assessment_id: assessment.id
        )

      assert %{type: :published_grading} = notification
    end

    test "receives notification when maunally graded [team submission]", %{
      assessment: assessment,
      team: team,
      team_submission: team_submission
    } do
      Notifications.write_notification_when_published(team_submission.id, :published_grading)

      team_members =
        Repo.all(from(tm in TeamMember, where: tm.team_id == ^team.id, preload: :student))

      students = Enum.map(team_members, & &1.student)

      Enum.each(students, fn student ->
        notification =
          Repo.get_by(Notification,
            course_reg_id: student.id,
            type: :published_grading,
            assessment_id: assessment.id
          )

        assert %{type: :published_grading} = notification
      end)
    end

    test "every student receives notifications when a new assessment is published", %{
      assessment: assessment,
      student: student
    } do
      students = [
        student | insert_list(3, :course_registration, %{course: student.course, role: :student})
      ]

      Notifications.write_notification_for_new_assessment(student.course_id, assessment.id)

      for student <- students do
        notification =
          Repo.get_by(Notification,
            course_reg_id: student.id,
            type: :new,
            assessment_id: assessment.id
          )

        assert %{type: :new} = notification
      end
    end
  end
end
