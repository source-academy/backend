defmodule CadetWeb.NotificationsControllerTest do
  use CadetWeb.ConnCase

  alias CadetWeb.NotificationsController

  test "swagger" do
    NotificationsController.swagger_definitions()
    NotificationsController.swagger_path_index(nil)
    NotificationsController.swagger_path_acknowledge(nil)
  end

  setup do
    course = insert(:course)
    assessment = insert(:assessment, %{is_published: true, course: course})
    avenger = insert(:course_registration, %{role: :staff, course: course})
    student = insert(:course_registration, %{role: :student, course: course})
    submission = insert(:submission, %{student: student, assessment: assessment})

    notifications =
      insert_list(3, :notification, %{
        read: false,
        assessment_id: assessment.id,
        course_reg_id: student.id
      }) ++
        insert_list(3, :notification, %{
          read: true,
          assessment_id: assessment.id,
          course_reg_id: student.id
        })

    {:ok,
     %{
       course: course,
       assessment: assessment,
       avenger: avenger,
       student: student,
       submission: submission,
       notifications: notifications
     }}
  end

  describe "GET /, unauthenticated" do
    test "/notifications", %{course: course, conn: conn} do
      conn = get(conn, build_url(course.id))
      assert response(conn, 401) =~ "Unauthorised"
    end
  end

  describe "POST /, unaunthenticated" do
    test "/notifications/acknowledge", %{course: course, conn: conn} do
      conn =
        post(conn, build_acknowledge_url(course.id), %{
          "notificationIds" => [1]
        })

      assert response(conn, 401) =~ "Unauthorised"
    end
  end

  describe "GET /notifications" do
    test "student fetches unread notifications", %{
      conn: conn,
      course: course,
      student: student,
      assessment: assessment,
      notifications: notifications
    } do
      expected =
        notifications
        |> Enum.filter(&(!&1.read))
        |> Enum.sort(&(&1.id < &2.id))
        |> Enum.map(
          &%{
            "id" => &1.id,
            "assessment_id" => &1.assessment_id,
            "submission_id" => nil,
            "type" => Atom.to_string(&1.type),
            "assessment" => %{
              "type" => assessment.config.type,
              "title" => assessment.title
            }
          }
        )

      results =
        conn
        |> sign_in(student.user)
        |> get(build_url(course.id))
        |> json_response(200)
        |> Enum.sort(&(&1["id"] < &2["id"]))

      assert results == expected
    end

    test "avenger fetches unread notifications", %{
      conn: conn,
      course: course,
      avenger: avenger,
      assessment: assessment,
      submission: submission
    } do
      notifications =
        insert_list(3, :notification, %{
          type: :submitted,
          read: false,
          assessment_id: assessment.id,
          submission_id: submission.id,
          course_reg_id: avenger.id
        })

      expected =
        notifications
        |> Enum.filter(&(!&1.read))
        |> Enum.sort(&(&1.id < &2.id))
        |> Enum.map(
          &%{
            "id" => &1.id,
            "assessment_id" => &1.assessment_id,
            "submission_id" => &1.submission_id,
            "type" => Atom.to_string(&1.type),
            "assessment" => %{
              "type" => assessment.config.type,
              "title" => assessment.title
            }
          }
        )

      results =
        conn
        |> sign_in(avenger.user)
        |> get(build_url(course.id))
        |> json_response(200)
        |> Enum.sort(&(&1["id"] < &2["id"]))

      assert results == expected
    end
  end

  describe "POST /notifications/acknowledge" do
    test "student acknowledges own notification", %{
      conn: conn,
      course: course,
      student: student,
      notifications: notifications
    } do
      conn =
        conn
        |> sign_in(student.user)
        |> post(build_acknowledge_url(course.id), %{
          "notificationIds" => [Enum.random(notifications).id]
        })

      assert response(conn, 200) == "OK"
    end

    test "other user not allowed to acknowledge notification that is not theirs", %{
      conn: conn,
      course: course,
      avenger: avenger,
      notifications: notifications
    } do
      conn =
        conn
        |> sign_in(avenger.user)
        |> post(build_acknowledge_url(course.id), %{
          "notificationIds" => [Enum.random(notifications).id]
        })

      assert response(conn, 404) == "Notification does not exist or does not belong to user"
    end
  end

  defp build_url(course_id), do: "/v2/courses/#{course_id}/notifications"
  defp build_acknowledge_url(course_id), do: "/v2/courses/#{course_id}/notifications/acknowledge"
end
