defmodule CadetWeb.NotificationControllerTest do
  use CadetWeb.ConnCase

  alias CadetWeb.NotificationController

  test "swagger" do
    NotificationController.swagger_definitions()
    NotificationController.swagger_path_index(nil)
    NotificationController.swagger_path_acknowledge(nil)
  end

  setup do
    assessment = insert(:assessment, %{is_published: true})
    avenger = insert(:user, %{role: :staff})
    student = insert(:user, %{role: :student})
    submission = insert(:submission, %{student: student, assessment: assessment})

    notifications =
      insert_list(3, :notification, %{
        read: false,
        assessment_id: assessment.id,
        user_id: student.id
      }) ++
        insert_list(3, :notification, %{
          read: true,
          assessment_id: assessment.id,
          user_id: student.id
        })

    {:ok,
     %{
       assessment: assessment,
       avenger: avenger,
       student: student,
       submission: submission,
       notifications: notifications
     }}
  end

  describe "GET /, unauthenticated" do
    test "/notification", %{conn: conn} do
      conn = get(conn, build_url())
      assert response(conn, 401) =~ "Unauthorised"
    end
  end

  describe "POST /, unaunthenticated" do
    test "/notification/:notification_id/acknowledge", %{conn: conn} do
      conn = post(conn, build_url(1))
      assert response(conn, 401) =~ "Unauthorised"
    end
  end

  describe "GET /notification" do
    test "student fetches unread notifications", %{
      conn: conn,
      student: student,
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
            "question_id" => &1.question_id,
            "submission_id" => nil,
            "read" => &1.read,
            "type" => Atom.to_string(&1.type)
          }
        )

      results =
        conn
        |> sign_in(student)
        |> get(build_url())
        |> json_response(200)
        |> Enum.sort(&(&1["id"] < &2["id"]))

      assert results == expected
    end

    test "avenger fetches unread notifications", %{
      conn: conn,
      avenger: avenger,
      submission: submission
    } do
      notifications =
        insert_list(3, :notification, %{
          type: :submitted,
          read: false,
          submission_id: submission.id,
          user_id: avenger.id
        })

      expected =
        notifications
        |> Enum.filter(&(!&1.read))
        |> Enum.sort(&(&1.id < &2.id))
        |> Enum.map(
          &%{
            "id" => &1.id,
            "assessment_id" => nil,
            "submission_id" => &1.submission_id,
            "question_id" => &1.question_id,
            "read" => &1.read,
            "type" => Atom.to_string(&1.type)
          }
        )

      results =
        conn
        |> sign_in(avenger)
        |> get(build_url())
        |> json_response(200)
        |> Enum.sort(&(&1["id"] < &2["id"]))

      assert results == expected
    end
  end

  describe "POST /notification/:notificationId/acknowledge" do
    test "student acknowledges own notification", %{
      conn: conn,
      student: student,
      notifications: notifications
    } do
      conn =
        conn
        |> sign_in(student)
        |> post(build_url(Enum.random(notifications).id))

      assert response(conn, 200) == "OK"
    end

    test "other user not allowed to acknowledge notification that is not theirs", %{
      conn: conn,
      avenger: avenger,
      notifications: notifications
    } do
      conn =
        conn
        |> sign_in(avenger)
        |> post(build_url(Enum.random(notifications).id))

      assert response(conn, 404) == "Notification does not exist or does not belong to user"
    end
  end

  defp build_url, do: "/v1/notification"
  defp build_url(notification_id), do: "/v1/notification/#{notification_id}/acknowledge"
end
