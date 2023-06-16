# Results of tests depends on the number of notifications implemented in Source Academy,
# test expected values have to be updated as more notification types are introduced
defmodule CadetWeb.AssessmentsControllerTest do
  use CadetWeb.ConnCase

  import Ecto.Query, warn: false

  alias Cadet.Notifications.{NotificationConfig, NotificationType}

  setup do
    course = insert(:course)
    assessment_config = insert(:assessment_config, %{course: course})
    assessment = insert(:assessment, %{is_published: true, course: course, config: assessment_config})
    avenger = insert(:course_registration, %{role: :staff, course: course})
    student = insert(:course_registration, %{role: :student, course: course})
    submission = insert(:submission, %{student: student, assessment: assessment})

    Ecto.Adapters.SQL.Sandbox.checkout(Cadet.Repo)

    course_noticonfig_query = from(
      nc in NotificationConfig,
      join: ntype in NotificationType,
      on: nc.notification_type_id == ntype.id,
      where: nc.course_id == ^course.id and is_nil(nc.assessment_config_id) and ntype.for_staff == true,
      limit: 1
    )
    course_noticonfig = Cadet.Repo.one(course_noticonfig_query)

    # insert a notification preference for the avenger
    avenger_preference = insert(:notification_preference, %{
      notification_config: course_noticonfig,
      course_reg: avenger,
      is_enabled: false
    })

    # insert 2 time options for the notification config
    time_options = insert_list(2, :time_option, %{notification_config: course_noticonfig})

    {:ok,
     %{
       course: course,
       assessment_config: assessment_config,
       assessment: assessment,
       avenger: avenger,
       student: student,
       submission: submission,
       course_noticonfig: course_noticonfig,
       avenger_preference: avenger_preference,
       time_options: time_options
     }}
  end

  describe "GET /v2/notifications/config/:course_id" do
    test "200 suceeds", %{course: course, conn: conn} do

      conn = get(conn, "/v2/notifications/config/#{course.id}")
      result = Jason.decode!(response(conn, 200))

      assert length(result) == 2
    end
  end

  describe "GET /v2/notifications/config/user/:course_reg_id" do
    test "200 succeeds for avenger", %{avenger: avenger, conn: conn} do
      conn = get(conn, "/v2/notifications/config/user/#{avenger.id}")
      result = Jason.decode!(response(conn, 200))

      assert length(result) == 2
    end

    test "200 succeeds for student", %{student: student, conn: conn} do
      conn = get(conn, "/v2/notifications/config/user/#{student.id}")
      result = Jason.decode!(response(conn, 200))

      assert length(result) == 0
    end

    test "400 fails, user does not exist", %{conn: conn} do
      conn = get(conn, "/v2/notifications/config/user/-1")
      assert response(conn, 400)
    end
  end

  describe "PUT /v2/notifications/config" do
    test "200 succeeds", %{course_noticonfig: course_noticonfig, conn: conn} do
      conn = put(conn, "/v2/notifications/config", %{
        "_json" => [%{:id => course_noticonfig.id, :isEnabled => true}]
      })
      result = Jason.decode!(response(conn, 200))

      assert length(result) == 1
      assert List.first(result)["isEnabled"] == true
    end
  end

  describe "PUT /v2/notifications/preferences" do
    test "200 succeeds, update", %{
      avenger_preference: avenger_preference,
      avenger: avenger,
      course_noticonfig: course_noticonfig,
      conn: conn
    } do
      conn = put(conn, "/v2/notifications/preferences", %{
        "_json" => [%{:id => avenger_preference.id, :courseRegId => avenger.id, :notificationConfigId => course_noticonfig.id, :isEnabled => true}]
      })
      result = Jason.decode!(response(conn, 200))

      assert length(result) == 1
      assert List.first(result)["isEnabled"] == true
    end
  end

  describe "GET /options/config/:noti_config_id" do
    test "200 succeeds", %{course_noticonfig: course_noticonfig, time_options: time_options, conn: conn} do
      conn = get(conn, "/v2/notifications/options/config/#{course_noticonfig.id}")
      result = Jason.decode!(response(conn, 200))

      assert length(result) == length(time_options)
      for {retrieved_to, to} <- Enum.zip(result, time_options) do
        assert retrieved_to["minutes"] == to.minutes
      end
    end

    test "200 succeeds, empty array as notification config record not found", %{conn: conn} do
      conn = get(conn, "/v2/notifications/options/config/-1")
      result = Jason.decode!(response(conn, 200))

      assert length(result) == 0
    end
  end

  # Due to unique constraint on the column 'minutes',
  # test cases may fail if the generator produces the same number
  describe "PUT /v2/notifications/options" do
    test "200 succeeds, update", %{
      time_options: time_options,
      course_noticonfig: course_noticonfig,
      conn: conn
    } do
      time_option = List.first(time_options)
      new_minutes = :rand.uniform(200)
      conn = put(conn, "/v2/notifications/options", %{
        "_json" => [%{:id => time_option.id, :notificationConfigId => course_noticonfig.id, :minutes => new_minutes}]
      })
      result = Jason.decode!(response(conn, 200))

      assert length(result) == 1
      assert List.first(result)["minutes"] == new_minutes
    end

    test "200 succeeds, insert", %{
      course_noticonfig: course_noticonfig,
      conn: conn
    } do
      minutes = :rand.uniform(500)
      conn = put(conn, "/v2/notifications/options", %{
        "_json" => [%{:notificationConfigId => course_noticonfig.id, :minutes => minutes}]
      })
      result = Jason.decode!(response(conn, 200))

      assert length(result) == 1
      assert List.first(result)["minutes"] == minutes
    end
  end

  describe "DELETE /v2/notifications/options" do
    test "200 succeeds", %{
      time_options: time_options,
      conn: conn
    } do
      time_option = List.first(time_options)
      conn = delete(conn, "/v2/notifications/options", %{
        "_json" => [time_option.id]
      })

      assert response(conn, 200)
    end
  end

  test "400 fails, no such time option", %{
    conn: conn
  } do
    conn = delete(conn, "/v2/notifications/options", %{
      "_json" => [-1]
    })
    assert response(conn, 400)

  end
end
