defmodule CadetWeb.AdminAssessmentsControllerTest do
  use CadetWeb.ConnCase
  use Timex

  import Ecto.Query
  import ExUnit.CaptureLog

  alias Cadet.Repo
  alias Cadet.Accounts.CourseRegistration
  alias Cadet.Assessments.{Assessment, Submission}
  alias Cadet.Test.XMLGenerator
  alias CadetWeb.AdminAssessmentsController

  @local_name "test/fixtures/local_repo"

  setup do
    File.rm_rf!(@local_name)

    on_exit(fn ->
      File.rm_rf!(@local_name)
    end)

    Cadet.Test.Seeds.assessments()
  end

  test "swagger" do
    AdminAssessmentsController.swagger_definitions()
    AdminAssessmentsController.swagger_path_index(nil)
    AdminAssessmentsController.swagger_path_create(nil)
    AdminAssessmentsController.swagger_path_delete(nil)
    AdminAssessmentsController.swagger_path_update(nil)
  end

  describe "GET /:course_reg_id, unauthenticated" do
    test "unauthorised", %{conn: conn, courses: %{course1: course1}} do
      course_reg = insert(:course_registration, %{course: course1, role: :student})

      conn
      |> get(build_user_assessments_url(course1.id, course_reg.id))
      |> response(401)
    end
  end

  describe "GET /:course_reg_id, student only" do
    @tag authenticate: :student
    test "unauthorised", %{conn: conn} do
      test_cr = conn.assigns.test_cr
      course = test_cr.course
      course_reg = insert(:course_registration, %{course: course, role: :student})

      conn
      |> get(build_user_assessments_url(course.id, course_reg.id))
      |> response(403)
    end
  end

  # this doesn't work
  describe "GET /:course_reg_id, staff only" do
    test "renders assessments overview of student by staff", %{
      conn: conn,
      courses: %{course1: course1},
      role_crs: %{staff: staff, student: student},
      assessments: assessments
    } do
      view_as = student

      expected =
        assessments
        |> Map.values()
        |> Enum.map(& &1.assessment)
        |> Enum.sort(&open_at_asc_comparator/2)
        |> Enum.map(
          &%{
            "courseId" => &1.course_id,
            "id" => &1.id,
            "title" => &1.title,
            "shortSummary" => &1.summary_short,
            "story" => &1.story,
            "number" => &1.number,
            "reading" => &1.reading,
            "openAt" => format_datetime(&1.open_at),
            "closeAt" => format_datetime(&1.close_at),
            "type" => &1.config.type,
            "isManuallyGraded" => &1.config.is_manually_graded,
            "coverImage" => &1.cover_picture,
            "maxTeamSize" => 1,
            "maxXp" => 4800,
            "status" => get_assessment_status(view_as, &1),
            "private" => false,
            "isPublished" => &1.is_published,
            "gradedCount" => 0,
            "questionCount" => 9,
            "xp" => if(&1.is_grading_published, do: (800 + 500 + 100) * 3, else: 0),
            "earlySubmissionXp" => &1.config.early_submission_xp,
            "hasVotingFeatures" => &1.has_voting_features,
            "hasTokenCounter" => &1.has_token_counter,
            "isVotingPublished" => false
          }
        )

      resp =
        conn
        |> sign_in(staff.user)
        |> get(build_user_assessments_url(course1.id, view_as.id))
        |> json_response(200)

      assert expected == resp
    end

    test "renders assessments overview of admin by staff", %{
      conn: conn,
      courses: %{course1: course1},
      role_crs: %{staff: staff, admin: admin},
      assessments: assessments
    } do
      view_as = admin

      expected =
        assessments
        |> Map.values()
        |> Enum.map(& &1.assessment)
        |> Enum.sort(&open_at_asc_comparator/2)
        |> Enum.map(
          &%{
            "courseId" => &1.course_id,
            "id" => &1.id,
            "title" => &1.title,
            "shortSummary" => &1.summary_short,
            "story" => &1.story,
            "number" => &1.number,
            "reading" => &1.reading,
            "openAt" => format_datetime(&1.open_at),
            "closeAt" => format_datetime(&1.close_at),
            "type" => &1.config.type,
            "isManuallyGraded" => &1.config.is_manually_graded,
            "coverImage" => &1.cover_picture,
            "maxTeamSize" => 1,
            "maxXp" => 4800,
            "status" => get_assessment_status(view_as, &1),
            "private" => false,
            "isPublished" => &1.is_published,
            "gradedCount" => 0,
            "questionCount" => 9,
            "xp" => 0,
            "earlySubmissionXp" => &1.config.early_submission_xp,
            "hasVotingFeatures" => &1.has_voting_features,
            "hasTokenCounter" => &1.has_token_counter,
            "isVotingPublished" => false
          }
        )

      resp =
        conn
        |> sign_in(staff.user)
        |> get(build_user_assessments_url(course1.id, view_as.id))
        |> json_response(200)

      assert expected == resp
    end
  end

  describe "POST /, unauthenticated" do
    test "unauthorized", %{
      conn: conn,
      courses: %{course1: course1},
      assessment_configs: [config | _]
    } do
      assessment =
        build(:assessment,
          course_id: course1.id,
          course: course1,
          config: config,
          config_id: config.id,
          is_published: true
        )

      questions = build_list(5, :question, assessment: nil)
      xml = XMLGenerator.generate_xml_for(assessment, questions)
      file = File.write("test/fixtures/local_repo/test.xml", xml)
      force_update = "false"
      body = %{assessment: file, forceUpdate: force_update}
      conn = post(conn, build_url(course1.id), body)
      assert response(conn, 401) =~ "Unauthorised"
    end
  end

  describe "POST /, student only" do
    @tag authenticate: :student
    test "unauthorized", %{conn: conn} do
      test_cr = conn.assigns.test_cr
      course = test_cr.course
      config = insert(:assessment_config, %{course: course})

      assessment =
        build(:assessment,
          course: course,
          course_id: course.id,
          config: config,
          config_id: config.id,
          is_published: true
        )

      questions = build_list(5, :question, assessment: nil)

      xml = XMLGenerator.generate_xml_for(assessment, questions)
      force_update = "false"
      body = %{assessment: xml, forceUpdate: force_update, assessmentConfigId: config.id}
      conn = post(conn, build_url(course.id), body)
      assert response(conn, 403) == "Forbidden"
    end
  end

  describe "POST /, non-admin staff only" do
    @tag authenticate: :staff
    test "unauthorized", %{conn: conn} do
      test_cr = conn.assigns.test_cr
      course = test_cr.course
      config = insert(:assessment_config, %{course: course})

      assessment =
        build(:assessment,
          course: course,
          course_id: course.id,
          config: config,
          config_id: config.id,
          is_published: true
        )

      questions = build_list(5, :question, assessment: nil)

      xml = XMLGenerator.generate_xml_for(assessment, questions)
      force_update = "false"
      body = %{assessment: xml, forceUpdate: force_update, assessmentConfigId: config.id}
      conn = post(conn, build_url(course.id), body)
      assert response(conn, 403) == "Forbidden"
    end
  end

  describe "POST /, admin only" do
    @tag authenticate: :admin
    test "successful", %{conn: conn} do
      test_cr = conn.assigns.test_cr
      course = test_cr.course
      config = insert(:assessment_config, %{course: course})

      assessment =
        build(:assessment,
          course: course,
          course_id: course.id,
          config: config,
          config_id: config.id,
          is_published: true
        )

      # contest assessment need to be added before assessment with voting questions can be added.
      contest_assessment = insert(:assessment, course: course, config: config)

      questions = [
        build(:programming_question),
        build(:mcq_question),
        build(:voting_question,
          question: build(:voting_question_content, contest_number: contest_assessment.number)
        )
      ]

      xml = XMLGenerator.generate_xml_for(assessment, questions)
      force_update = "false"
      path = Path.join(@local_name, "connTest")
      file_name = "test.xml"
      location = Path.join(path, file_name)
      File.mkdir_p!(path)
      File.write!(location, xml)

      formdata = %Plug.Upload{
        content_type: "text/xml",
        filename: file_name,
        path: location
      }

      body = %{
        assessment: %{file: formdata},
        forceUpdate: force_update,
        assessmentConfigId: config.id
      }

      conn = post(conn, build_url(course.id), body)
      number = assessment.number

      expected_assessment =
        Assessment
        |> where(number: ^number)
        |> Repo.one()

      assert response(conn, 200) == "OK"
      assert expected_assessment != nil
    end

    @tag authenticate: :admin
    test "upload empty xml", %{conn: conn} do
      test_cr = conn.assigns.test_cr
      course = test_cr.course
      config = insert(:assessment_config, %{course: course})

      xml = ""
      force_update = "true"
      path = Path.join(@local_name, "connTest")
      file_name = "test.xml"
      location = Path.join(path, file_name)
      File.mkdir_p!(path)
      File.write!(location, xml)

      formdata = %Plug.Upload{
        content_type: "text/xml",
        filename: file_name,
        path: location
      }

      body = %{
        assessment: %{file: formdata},
        forceUpdate: force_update,
        assessmentConfigId: config.id
      }

      err_msg =
        "Invalid XML fatal expected_element_start_tag file file_name_unknown line 1 col 1 "

      assert capture_log(fn ->
               conn = post(conn, build_url(course.id), body)
               assert(response(conn, 400) == err_msg)
             end) =~ ~r/.*fatal: :expected_element_start_tag.*/
    end
  end

  describe "DELETE /:assessment_id, unauthenticated" do
    test "unauthorized", %{conn: conn} do
      assessment = insert(:assessment)
      conn = delete(conn, build_url(assessment.course.id, assessment.id))
      assert response(conn, 401) =~ "Unauthorised"
    end
  end

  describe "DELETE /:assessment_id, student only" do
    @tag authenticate: :student
    test "unauthorized", %{conn: conn} do
      test_cr = conn.assigns.test_cr
      course = test_cr.course
      config = insert(:assessment_config, %{course: course})
      assessment = insert(:assessment, %{course: course, config: config})
      conn = delete(conn, build_url(course.id, assessment.id))
      assert response(conn, 403) == "Forbidden"
    end
  end

  describe "DELETE /:assessment_id, staff only" do
    @tag authenticate: :staff
    test "unauthorized", %{conn: conn} do
      test_cr = conn.assigns.test_cr
      course = test_cr.course
      config = insert(:assessment_config, %{course: course})
      assessment = insert(:assessment, %{course: course, config: config})
      conn = delete(conn, build_url(course.id, assessment.id))
      assert response(conn, 403) == "Forbidden"
    end
  end

  describe "DELETE /:assessment_id, admin only" do
    @tag authenticate: :admin
    test "successful", %{conn: conn} do
      test_cr = conn.assigns.test_cr
      course = test_cr.course
      config = insert(:assessment_config, %{course: course})
      assessment = insert(:assessment, %{course: course, config: config})
      conn = delete(conn, build_url(course.id, assessment.id))
      assert response(conn, 200) == "OK"
      assert is_nil(Repo.get(Assessment, assessment.id))
    end

    @tag authenticate: :admin
    test "error due to different course", %{conn: conn} do
      test_cr = conn.assigns.test_cr
      course = test_cr.course
      another_course = insert(:course)
      config = insert(:assessment_config, %{course: another_course})
      assessment = insert(:assessment, %{course: another_course, config: config})

      conn = delete(conn, build_url(course.id, assessment.id))
      assert response(conn, 403) == "User not allow to delete assessments from another course"
      refute is_nil(Repo.get(Assessment, assessment.id))
    end
  end

  describe "POST /:assessment_id, unauthenticated, publish" do
    test "unauthorized", %{conn: conn} do
      assessment = insert(:assessment)
      conn = post(conn, build_url(assessment.course.id, assessment.id), %{isPublished: true})
      assert response(conn, 401) =~ "Unauthorised"
    end
  end

  describe "POST /:assessment_id, student only, publish" do
    @tag authenticate: :student
    test "forbidden", %{conn: conn} do
      test_cr = conn.assigns.test_cr
      course = test_cr.course
      config = insert(:assessment_config, %{course: course})
      assessment = insert(:assessment, %{course: course, config: config})
      conn = post(conn, build_url(course.id, assessment.id), %{isPublished: true})
      assert response(conn, 403) == "Forbidden"
    end
  end

  describe "POST /:assessment_id, non-admin staff only, publish" do
    @tag authenticate: :staff
    test "forbidden", %{conn: conn} do
      test_cr = conn.assigns.test_cr
      course = test_cr.course
      config = insert(:assessment_config, %{course: course})
      assessment = insert(:assessment, %{course: course, config: config})
      conn = post(conn, build_url(course.id, assessment.id), %{isPublished: true})
      assert response(conn, 403) == "Forbidden"
    end
  end

  describe "POST /:assessment_id, admin only, publish" do
    @tag authenticate: :admin
    test "successful toggle from published to unpublished", %{conn: conn} do
      test_cr = conn.assigns.test_cr
      course = test_cr.course
      config = insert(:assessment_config, %{course: course})
      assessment = insert(:assessment, %{course: course, config: config})
      conn = post(conn, build_url(course.id, assessment.id), %{isPublished: false})
      expected = Repo.get(Assessment, assessment.id).is_published
      assert response(conn, 200) == "OK"
      refute expected
    end

    @tag authenticate: :admin
    test "successful toggle from unpublished to published", %{conn: conn} do
      test_cr = conn.assigns.test_cr
      course = test_cr.course
      config = insert(:assessment_config, %{course: course})
      assessment = insert(:assessment, %{course: course, config: config, is_published: false})
      conn = post(conn, build_url(course.id, assessment.id), %{isPublished: true})
      expected = Repo.get(Assessment, assessment.id).is_published
      assert response(conn, 200) == "OK"
      assert expected
    end
  end

  describe "POST /:assessment_id, unauthenticated" do
    test "unauthorized", %{conn: conn} do
      assessment = insert(:assessment)
      conn = post(conn, build_url(assessment.course.id, assessment.id))
      assert response(conn, 401) =~ "Unauthorised"
    end
  end

  describe "POST /:assessment_id, student only" do
    @tag authenticate: :student
    test "forbidden", %{conn: conn} do
      test_cr = conn.assigns.test_cr
      course = test_cr.course
      config = insert(:assessment_config, %{course: course})
      assessment = insert(:assessment, %{course: course, config: config})

      new_open_at =
        Timex.now()
        |> Timex.beginning_of_day()
        |> Timex.shift(days: 3)
        |> Timex.shift(hours: 4)

      new_open_at_string =
        new_open_at
        |> Timex.format!("{ISO:Extended}")

      new_close_at = Timex.shift(new_open_at, days: 7)

      new_close_at_string =
        new_close_at
        |> Timex.format!("{ISO:Extended}")

      new_dates = %{openAt: new_open_at_string, closeAt: new_close_at_string}
      conn = post(conn, build_url(course.id, assessment.id), new_dates)
      assert response(conn, 403) == "Forbidden"
    end
  end

  describe "POST /:assessment_id, non-admin staff only" do
    @tag authenticate: :staff
    test "forbidden", %{conn: conn} do
      test_cr = conn.assigns.test_cr
      course = test_cr.course
      config = insert(:assessment_config, %{course: course})
      assessment = insert(:assessment, %{course: course, config: config})

      new_open_at =
        Timex.now()
        |> Timex.beginning_of_day()
        |> Timex.shift(days: 3)
        |> Timex.shift(hours: 4)

      new_open_at_string =
        new_open_at
        |> Timex.format!("{ISO:Extended}")

      new_close_at = Timex.shift(new_open_at, days: 7)

      new_close_at_string =
        new_close_at
        |> Timex.format!("{ISO:Extended}")

      new_dates = %{openAt: new_open_at_string, closeAt: new_close_at_string}
      conn = post(conn, build_url(course.id, assessment.id), new_dates)
      assert response(conn, 403) == "Forbidden"
    end
  end

  describe "POST /:assessment_id, admin only" do
    @tag authenticate: :admin
    test "successful", %{conn: conn} do
      test_cr = conn.assigns.test_cr
      course = test_cr.course
      config = insert(:assessment_config, %{course: course})

      open_at =
        Timex.now()
        |> Timex.beginning_of_day()
        |> Timex.shift(days: 3)
        |> Timex.shift(hours: 4)

      close_at = Timex.shift(open_at, days: 7)

      assessment =
        insert(:assessment, %{
          course: course,
          config: config,
          open_at: open_at,
          close_at: close_at
        })

      new_open_at =
        open_at
        |> Timex.shift(days: 3)

      new_open_at_string =
        new_open_at
        |> Timex.format!("{ISO:Extended}")

      new_close_at =
        close_at
        |> Timex.shift(days: 5)

      new_close_at_string =
        new_close_at
        |> Timex.format!("{ISO:Extended}")

      new_dates = %{openAt: new_open_at_string, closeAt: new_close_at_string}

      conn =
        conn
        |> post(build_url(course.id, assessment.id), new_dates)

      assessment = Repo.get(Assessment, assessment.id)
      assert response(conn, 200) == "OK"
      assert [assessment.open_at, assessment.close_at] == [new_open_at, new_close_at]
    end

    @tag authenticate: :admin
    test "allowed to change open time of opened assessments", %{conn: conn} do
      test_cr = conn.assigns.test_cr
      course = test_cr.course
      config = insert(:assessment_config, %{course: course})

      open_at =
        Timex.now()
        |> Timex.beginning_of_day()
        |> Timex.shift(days: -3)
        |> Timex.shift(hours: 4)

      close_at = Timex.shift(open_at, days: 7)

      assessment =
        insert(:assessment, %{
          course: course,
          config: config,
          open_at: open_at,
          close_at: close_at
        })

      new_open_at =
        open_at
        |> Timex.shift(days: 6)

      new_open_at_string =
        new_open_at
        |> Timex.format!("{ISO:Extended}")

      close_at_string =
        close_at
        |> Timex.format!("{ISO:Extended}")

      new_dates = %{openAt: new_open_at_string, closeAt: close_at_string}

      conn =
        conn
        |> post(build_url(course.id, assessment.id), new_dates)

      assessment = Repo.get(Assessment, assessment.id)
      assert response(conn, 200) == "OK"
      assert [assessment.open_at, assessment.close_at] == [new_open_at, close_at]
    end

    @tag authenticate: :admin
    test "not allowed to set close time to before open time", %{conn: conn} do
      test_cr = conn.assigns.test_cr
      course = test_cr.course
      config = insert(:assessment_config, %{course: course})

      open_at =
        Timex.now()
        |> Timex.beginning_of_day()
        |> Timex.shift(days: 3)
        |> Timex.shift(hours: 4)

      close_at = Timex.shift(open_at, days: 7)

      assessment =
        insert(:assessment, %{
          course: course,
          config: config,
          open_at: open_at,
          close_at: close_at
        })

      new_close_at =
        open_at
        |> Timex.shift(days: -1)

      new_close_at_string =
        new_close_at
        |> Timex.format!("{ISO:Extended}")

      open_at_string =
        open_at
        |> Timex.format!("{ISO:Extended}")

      new_dates = %{openAt: open_at_string, closeAt: new_close_at_string}

      conn =
        conn
        |> post(build_url(course.id, assessment.id), new_dates)

      assessment = Repo.get(Assessment, assessment.id)
      assert response(conn, 400) == "New end date should occur after new opening date"
      assert [assessment.open_at, assessment.close_at] == [open_at, close_at]
    end

    @tag authenticate: :admin
    test "successful, set close time to before current time", %{conn: conn} do
      test_cr = conn.assigns.test_cr
      course = test_cr.course
      config = insert(:assessment_config, %{course: course})

      open_at =
        Timex.now()
        |> Timex.beginning_of_day()
        |> Timex.shift(days: -3)
        |> Timex.shift(hours: 4)

      close_at = Timex.shift(open_at, days: 7)

      assessment =
        insert(:assessment, %{
          course: course,
          config: config,
          open_at: open_at,
          close_at: close_at
        })

      new_close_at =
        Timex.now()
        |> Timex.shift(days: -1)

      new_close_at_string =
        new_close_at
        |> Timex.format!("{ISO:Extended}")

      open_at_string =
        open_at
        |> Timex.format!("{ISO:Extended}")

      new_dates = %{openAt: open_at_string, closeAt: new_close_at_string}

      conn =
        conn
        |> post(build_url(course.id, assessment.id), new_dates)

      assessment = Repo.get(Assessment, assessment.id)
      assert response(conn, 200) == "OK"
      assert [assessment.open_at, assessment.close_at] == [open_at, new_close_at]
    end

    @tag authenticate: :admin
    test "successful, set open time to before current time", %{conn: conn} do
      test_cr = conn.assigns.test_cr
      course = test_cr.course
      config = insert(:assessment_config, %{course: course})

      open_at =
        Timex.now()
        |> Timex.beginning_of_day()
        |> Timex.shift(days: 3)
        |> Timex.shift(hours: 4)

      close_at = Timex.shift(open_at, days: 7)

      assessment =
        insert(:assessment, %{
          course: course,
          config: config,
          open_at: open_at,
          close_at: close_at
        })

      new_open_at =
        Timex.now()
        |> Timex.shift(days: -1)

      new_open_at_string =
        new_open_at
        |> Timex.format!("{ISO:Extended}")

      close_at_string =
        close_at
        |> Timex.format!("{ISO:Extended}")

      new_dates = %{openAt: new_open_at_string, closeAt: close_at_string}

      conn =
        conn
        |> post(build_url(course.id, assessment.id), new_dates)

      assessment = Repo.get(Assessment, assessment.id)
      assert response(conn, 200) == "OK"
      assert [assessment.open_at, assessment.close_at] == [new_open_at, close_at]
    end

    @tag authenticate: :admin
    test "successful, set hasTokenCounter and hasVotingFeatures to true", %{conn: conn} do
      test_cr = conn.assigns.test_cr
      course = test_cr.course
      config = insert(:assessment_config, %{course: course})

      assessment =
        insert(:assessment, %{
          course: course,
          config: config,
          has_token_counter: false,
          has_voting_features: false
        })

      new_has_token_counter = true
      new_has_voting_features = true

      new_assessment_setting = %{
        hasTokenCounter: new_has_token_counter,
        hasVotingFeatures: new_has_voting_features
      }

      conn =
        conn
        |> post(build_url(course.id, assessment.id), new_assessment_setting)

      assessment = Repo.get(Assessment, assessment.id)
      assert response(conn, 200) == "OK"

      assert [assessment.has_token_counter, assessment.has_voting_features] == [
               new_has_token_counter,
               new_has_voting_features
             ]
    end

    @tag authenticate: :admin
    test "successful, set hasTokenCounter and hasVotingFeatures to false", %{conn: conn} do
      test_cr = conn.assigns.test_cr
      course = test_cr.course
      config = insert(:assessment_config, %{course: course})

      assessment =
        insert(:assessment, %{
          course: course,
          config: config,
          has_token_counter: true,
          has_voting_features: true
        })

      new_has_token_counter = false
      new_has_voting_features = false

      new_assessment_setting = %{
        hasTokenCounter: new_has_token_counter,
        hasVotingFeatures: new_has_voting_features
      }

      conn =
        conn
        |> post(build_url(course.id, assessment.id), new_assessment_setting)

      assessment = Repo.get(Assessment, assessment.id)
      assert response(conn, 200) == "OK"

      assert [assessment.has_token_counter, assessment.has_voting_features] == [
               new_has_token_counter,
               new_has_voting_features
             ]
    end
  end

  defp build_url(course_id), do: "/v2/courses/#{course_id}/admin/assessments/"

  defp build_url(course_id, assessment_id),
    do: "/v2/courses/#{course_id}/admin/assessments/#{assessment_id}"

  defp build_user_assessments_url(course_id, course_reg_id),
    do: "/v2/courses/#{course_id}/admin/users/#{course_reg_id}/assessments"

  defp open_at_asc_comparator(x, y), do: Timex.before?(x.open_at, y.open_at)

  defp get_assessment_status(course_reg = %CourseRegistration{}, assessment = %Assessment{}) do
    submission =
      Submission
      |> where(student_id: ^course_reg.id)
      |> where(assessment_id: ^assessment.id)
      |> Repo.one()

    (submission && submission.status |> Atom.to_string()) || "not_attempted"
  end
end
