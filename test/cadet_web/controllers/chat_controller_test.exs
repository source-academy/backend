defmodule CadetWeb.ChatControllerTest do
  use CadetWeb.ConnCase

  alias Cadet.Accounts.Notification
  alias Cadet.Repo

  setup do
    assessment = insert(:assessment, %{is_published: true})
    avenger = insert(:user, %{role: :staff})
    group = insert(:group, %{leader: avenger})
    student = insert(:user, %{role: :student, group: group})
    submission = insert(:submission, %{student: student, assessment: assessment})

    {:ok,
     %{
       assessment: assessment,
       avenger: avenger,
       student: student,
       submission: submission
     }}
  end

  describe "POST /chat/notify, unaunthenticated" do
    test "/chat/notify", %{conn: conn} do
      conn =
        post(conn, build_notify_url(), %{
          "assessmentId" => 1
        })

      assert response(conn, 401) =~ "Unauthorised"
    end
  end

  describe "POST /chat/notify" do
    test "student writes a message, should notify avenger", %{
      conn: conn,
      assessment: assessment,
      avenger: avenger,
      student: student,
      submission: submission
    } do
      conn =
        conn
        |> sign_in(student)
        |> post(build_notify_url(), %{
          "assessmentId" => assessment.id
        })

      assert response(conn, 200) == "OK"

      notification =
        Repo.get_by(Notification,
          user_id: avenger.id,
          type: :new_message,
          submission_id: submission.id
        )

      assert %{type: :new_message} = notification
    end

    test "avenger writes a message, should notify student", %{
      conn: conn,
      assessment: assessment,
      avenger: avenger,
      student: student,
      submission: submission
    } do
      conn =
        conn
        |> sign_in(avenger)
        |> post(build_notify_url(), %{
          "submissionId" => submission.id
        })

      assert response(conn, 200) == "OK"

      notification =
        Repo.get_by(Notification,
          user_id: student.id,
          type: :new_message,
          assessment_id: assessment.id
        )

      assert %{type: :new_message} = notification
    end

    @tag authenticate: :admin
    test "admin doesnt write notifications", %{
      conn: conn
    } do
      conn =
        post(conn, build_notify_url(), %{
          "submissionId" => 12_345
        })

      assert response(conn, 400) =~ "Invalid Role"
    end

    @tag authenticate: :student
    test "bad parameters, student", %{
      conn: conn
    } do
      conn = post(conn, build_notify_url(), %{})

      assert response(conn, 500) =~ "Internal server error"
    end

    @tag authenticate: :staff
    test "bad parameters, staff", %{
      conn: conn
    } do
      conn = post(conn, build_notify_url(), %{})

      assert response(conn, 500) =~ "Internal server error"
    end
  end

  defp build_notify_url, do: "/v1/chat/notify"
end
