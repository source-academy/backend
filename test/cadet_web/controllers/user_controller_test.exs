defmodule CadetWeb.UserControllerTest do
  use CadetWeb.ConnCase

  import Cadet.Factory

  alias CadetWeb.UserController
  # alias Cadet.Assessments.{Assessment, Submission}
  alias Cadet.Accounts.{User, CourseRegistration}
  alias Cadet.{Repo, Courses}

  test "swagger" do
    assert is_map(UserController.swagger_definitions())
    assert is_map(UserController.swagger_path_index(nil))
  end

  describe "GET v2/user" do
    @tag authenticate: :student
    test "success, student non-story fields", %{conn: conn} do
      user = conn.assigns.current_user
      course = user.latest_viewed_course
      config2 = insert(:assessment_config, %{order: 2, type: "test type 2", course: course})
      config3 = insert(:assessment_config, %{order: 3, type: "test type 3", course: course})
      config1 = insert(:assessment_config, %{order: 1, type: "test type 1", course: course})
      cr = Repo.get_by(CourseRegistration, course_id: course.id, user_id: user.id)
      another_cr = insert(:course_registration, %{user: user, role: :admin})
      assessment = insert(:assessment, %{is_published: true, course: course})
      question = insert(:question, %{assessment: assessment})

      submission =
        insert(:submission, %{
          assessment: assessment,
          student: cr,
          status: :submitted,
          xp_bonus: 100
        })

      insert(:answer, %{
        question: question,
        submission: submission,
        xp: 20,
        xp_adjustment: -10
      })

      not_submitted_assessment = insert(:assessment, %{is_published: true, course: course})
      not_submitted_question = insert(:question, assessment: not_submitted_assessment)

      not_submitted_submission =
        insert(:submission, %{assessment: not_submitted_assessment, student: cr})

      insert(
        :answer,
        question: not_submitted_question,
        submission: not_submitted_submission
      )

      resp =
        conn
        |> get("/v2/user")
        |> json_response(200)
        |> put_in(["courseRegistration", "story"], nil)

      expected = %{
        "user" => %{
          "userId" => user.id,
          "name" => user.name,
          "courses" => [
            %{
              "courseId" => user.latest_viewed_course_id,
              "courseShortName" => "CS1101S",
              "courseName" => "Programming Methodology",
              "viewable" => true,
              "role" => "#{cr.role}"
            },
            %{
              "courseId" => another_cr.course_id,
              "courseShortName" => "CS1101S",
              "courseName" => "Programming Methodology",
              "viewable" => true,
              "role" => "#{another_cr.role}"
            }
          ]
        },
        "courseRegistration" => %{
          "courseRegId" => cr.id,
          "courseId" => course.id,
          "role" => "#{cr.role}",
          "group" => nil,
          "xp" => 110,
          "maxXp" => question.max_xp,
          "gameStates" => %{},
          "story" => nil,
          "agreedToResearch" => nil
        },
        "courseConfiguration" => %{
          "enableAchievements" => true,
          "enableGame" => true,
          "enableSourcecast" => true,
          "courseShortName" => "CS1101S",
          "moduleHelpText" => "Help Text",
          "courseName" => "Programming Methodology",
          "sourceChapter" => 1,
          "sourceVariant" => "default",
          "viewable" => true,
          "assetsPrefix" => Courses.assets_prefix(course)
        },
        "assessmentConfigurations" => [
          %{
            "type" => "test type 1",
            "displayInDashboard" => true,
            "isManuallyGraded" => true,
            "assessmentConfigId" => config1.id,
            "earlySubmissionXp" => 200,
            "hoursBeforeEarlyXpDecay" => 48
          },
          %{
            "type" => "test type 2",
            "displayInDashboard" => true,
            "isManuallyGraded" => true,
            "assessmentConfigId" => config2.id,
            "earlySubmissionXp" => 200,
            "hoursBeforeEarlyXpDecay" => 48
          },
          %{
            "type" => "test type 3",
            "displayInDashboard" => true,
            "isManuallyGraded" => true,
            "assessmentConfigId" => config3.id,
            "earlySubmissionXp" => 200,
            "hoursBeforeEarlyXpDecay" => 48
          }
        ]
      }

      assert expected == resp
    end

    @tag sign_in: %{latest_viewed_course: nil}
    test "success, no latest_viewed_course", %{conn: conn} do
      user = conn.assigns.current_user

      resp =
        conn
        |> get("/v2/user")
        |> json_response(200)

      expected = %{
        "user" => %{
          "userId" => user.id,
          "name" => user.name,
          "courses" => []
        },
        "courseRegistration" => nil,
        "courseConfiguration" => nil,
        "assessmentConfigurations" => nil
      }

      assert expected == resp
    end

    test "unauthorized", %{conn: conn} do
      conn = get(conn, "/v2/user", nil)
      assert response(conn, 401) =~ "Unauthorised"
    end
  end

  describe "GET /v2/user/latest_viewed_course" do
    @tag authenticate: :student
    test "success, student non-story fields", %{conn: conn} do
      user = conn.assigns.current_user
      course = user.latest_viewed_course
      cr = Repo.get_by(CourseRegistration, course_id: course.id, user_id: user.id)
      _another_cr = insert(:course_registration, %{user: user})
      assessment = insert(:assessment, %{is_published: true, course: course})
      question = insert(:question, %{assessment: assessment})

      submission =
        insert(:submission, %{
          assessment: assessment,
          student: cr,
          status: :submitted,
          xp_bonus: 100
        })

      insert(:answer, %{
        question: question,
        submission: submission,
        xp: 20,
        xp_adjustment: -10
      })

      not_submitted_assessment = insert(:assessment, %{is_published: true, course: course})
      not_submitted_question = insert(:question, assessment: not_submitted_assessment)

      not_submitted_submission =
        insert(:submission, %{assessment: not_submitted_assessment, student: cr})

      insert(
        :answer,
        question: not_submitted_question,
        submission: not_submitted_submission
      )

      resp =
        conn
        |> get("/v2/user/latest_viewed_course")
        |> json_response(200)
        |> put_in(["courseRegistration", "story"], nil)

      expected = %{
        "courseRegistration" => %{
          "courseRegId" => cr.id,
          "courseId" => course.id,
          "role" => "#{cr.role}",
          "group" => nil,
          "xp" => 110,
          "maxXp" => question.max_xp,
          "gameStates" => %{},
          "story" => nil,
          "agreedToResearch" => nil
        },
        "courseConfiguration" => %{
          "enableAchievements" => true,
          "enableGame" => true,
          "enableSourcecast" => true,
          "courseShortName" => "CS1101S",
          "moduleHelpText" => "Help Text",
          "courseName" => "Programming Methodology",
          "sourceChapter" => 1,
          "sourceVariant" => "default",
          "viewable" => true,
          "assetsPrefix" => Courses.assets_prefix(course)
        },
        "assessmentConfigurations" => []
      }

      assert expected == resp
    end

    @tag sign_in: %{latest_viewed_course: nil}
    test "success, no latest_viewed_course", %{conn: conn} do
      resp =
        conn
        |> get("/v2/user/latest_viewed_course")
        |> json_response(200)

      expected = %{
        "courseRegistration" => nil,
        "courseConfiguration" => nil,
        "assessmentConfigurations" => nil
      }

      assert expected == resp
    end

    test "unauthorized", %{conn: conn} do
      conn = get(conn, "/v2/user/latest_viewed_course", nil)
      assert response(conn, 401) =~ "Unauthorised"
    end
  end

  describe "PUT /v2/user/latest_viewed_course/{course_id}" do
    @tag authenticate: :student
    test "success, updating game state", %{conn: conn} do
      user = conn.assigns.current_user
      new_course = insert(:course)
      insert(:course_registration, %{user: user, course: new_course})

      conn
      |> put("/v2/user/latest_viewed_course", %{"courseId" => new_course.id})
      |> response(200)

      updated_user = Repo.get(User, user.id)

      assert new_course.id == updated_user.latest_viewed_course_id
    end
  end

  describe "PUT /v2/courses/{course_id}/user/game_states" do
    @tag authenticate: :student
    test "success, updating game state", %{conn: conn} do
      user = conn.assigns.current_user
      course_id = conn.assigns.course_id

      new_game_states = %{
        "gameSaveStates" => %{"1" => %{}, "2" => %{}},
        "userSaveState" => %{}
      }

      conn
      |> put(build_url(course_id) <> "/game_states", %{"gameStates" => new_game_states})
      |> response(200)

      updated_cr = Repo.get_by(CourseRegistration, course_id: course_id, user_id: user.id)

      assert new_game_states == updated_cr.game_states
    end
  end

  describe "PUT /v2/courses/{course_id}/user/research_agreement" do
    @tag authenticate: :student
    test "success, updating research agreement", %{conn: conn} do
      user = conn.assigns.current_user
      course_id = conn.assigns.course_id

      params = %{
        "agreedToResearch" => true
      }

      assert is_nil(
               CourseRegistration
               |> Repo.get_by(course_id: course_id, user_id: user.id)
               |> Map.fetch!(:agreed_to_research)
             )

      conn
      |> put(build_url(course_id) <> "/research_agreement", params)
      |> response(200)

      updated_cr = Repo.get_by(CourseRegistration, course_id: course_id, user_id: user.id)
      assert updated_cr.agreed_to_research == true
    end
  end

  defp build_url(course_id), do: "/v2/courses/#{course_id}/user"
end
