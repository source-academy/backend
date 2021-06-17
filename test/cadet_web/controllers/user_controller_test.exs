defmodule CadetWeb.UserControllerTest do
  use CadetWeb.ConnCase

  import Cadet.Factory

  alias Cadet.Repo
  alias CadetWeb.UserController
  # alias Cadet.Assessments.{Assessment, Submission}
  alias Cadet.Accounts.{User, CourseRegistration}

  test "swagger" do
    assert is_map(UserController.swagger_definitions())
    assert is_map(UserController.swagger_path_index(nil))
  end

  describe "GET v2/user" do
    @tag authenticate: :student
    test "success, student non-story fields", %{conn: conn} do
      user = conn.assigns.current_user
      course = user.latest_viewed
      insert(:assessment_type, %{order: 2, type: "test type 2", course: course})
      insert(:assessment_type, %{order: 3, type: "test type 3", course: course})
      insert(:assessment_type, %{order: 1, type: "test type 1", course: course})
      cr = Repo.get_by(CourseRegistration, course_id: course.id, user_id: user.id)
      another_cr = insert(:course_registration, %{user: user})
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
        submission: not_submitted_submission,
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
              "courseId" => user.latest_viewed_id,
              "courseShortName" => "CS1101S",
              "courseName" => "Programming Methodology",
              "viewable" => true
            },
            %{
              "courseId" => another_cr.course_id,
              "courseShortName" => "CS1101S",
              "courseName" => "Programming Methodology",
              "viewable" => true
            }
          ]
        },
        "courseRegistration" => %{
          "courseId" => course.id,
          "role" => "#{cr.role}",
          "group" => nil,
          "xp" => 110,
          "maxXp" => question.max_xp,
          "gameStates" => %{},
          "story" => nil
        },
        "courseConfiguration" => %{
          "assessmentTypes" => ["test type 1", "test type 2", "test type 3"],
          "enableAchievements" => true,
          "enableGame" => true,
          "enableSourcecast" => true,
          "courseShortName" => "CS1101S",
          "moduleHelpText" => "Help Text",
          "courseName" => "Programming Methodology",
          "sourceChapter" => 1,
          "sourceVariant" => "default",
          "viewable" => true
        }
      }

      assert expected == resp
    end

    @tag sign_in: %{latest_viewed: nil}
    test "success, no latest_viewed course", %{conn: conn} do
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
        "courseConfiguration" => nil
      }

      assert expected == resp
    end

    # # This also tests for the case where assessment has no submission
    # @tag authenticate: :student
    # test "success, student story ordering", %{conn: conn} do
    #   early_assessments = build_assessments_starting_at(Timex.shift(Timex.now(), days: -3))
    #   late_assessments = build_assessments_starting_at(Timex.shift(Timex.now(), days: -1))

    #   for assessment <- early_assessments ++ late_assessments do
    #     resp_story =
    #       conn
    #       |> get("/v2/user")
    #       |> json_response(200)
    #       |> Map.get("latestViewedCourse").story

    #     expected_story = %{
    #       "story" => assessment.story,
    #       "playStory" => true
    #     }

    #     assert resp_story == expected_story

    #     {:ok, _} = Repo.delete(assessment)
    #   end
    # end

    # @tag authenticate: :student
    # test "success, student story skips assessment without story", %{conn: conn} do
    #   assessments = build_assessments_starting_at(Timex.shift(Timex.now(), days: -1))

    #   assessments
    #   |> List.first()
    #   |> Assessment.changeset(%{story: nil})
    #   |> Repo.update()

    #   resp_story =
    #     conn
    #     |> get("/v2/user")
    #     |> json_response(200)
    #     |> Map.get("story")

    #   expected_story = %{
    #     "story" => Enum.fetch!(assessments, 1).story,
    #     "playStory" => true
    #   }

    #   assert resp_story == expected_story
    # end

    # @tag authenticate: :student
    # test "success, student story skips unopen assessments", %{conn: conn} do
    #   build_assessments_starting_at(Timex.shift(Timex.now(), days: 1))
    #   build_assessments_starting_at(Timex.shift(Timex.now(), months: -1))

    #   valid_assessments = build_assessments_starting_at(Timex.shift(Timex.now(), days: -1))

    #   for assessment <- valid_assessments do
    #     assessment
    #     |> Assessment.changeset(%{is_published: false})
    #     |> Repo.update!()
    #   end

    #   resp_story =
    #     conn
    #     |> get("/v2/user")
    #     |> json_response(200)
    #     |> Map.get("story")

    #   expected_story = %{
    #     "story" => nil,
    #     "playStory" => false
    #   }

    #   assert resp_story == expected_story
    # end

    # @tag authenticate: :student
    # test "success, student story skips attempting/attempted/submitted", %{conn: conn} do
    #   user = conn.assigns.current_user

    #   early_assessments = build_assessments_starting_at(Timex.shift(Timex.now(), days: -3))
    #   late_assessments = build_assessments_starting_at(Timex.shift(Timex.now(), days: -1))

    #   # Submit for i-th assessment, expect (i+1)th story to be returned
    #   for status <- [:attempting, :attempted, :submitted] do
    #     for [tester, checker] <-
    #           Enum.chunk_every(early_assessments ++ late_assessments, 2, 1, :discard) do
    #       insert(:submission, %{student: user, assessment: tester, status: status})

    #       resp_story =
    #         conn
    #         |> get("/v2/user")
    #         |> json_response(200)
    #         |> Map.get("story")

    #       expected_story = %{
    #         "story" => checker.story,
    #         "playStory" => true
    #       }

    #       assert resp_story == expected_story
    #     end

    #     Repo.delete_all(Submission)
    #   end
    # end

    # @tag authenticate: :student
    # test "success, return most recent assessment when all are attempted", %{conn: conn} do
    #   user = conn.assigns.current_user

    #   early_assessments = build_assessments_starting_at(Timex.shift(Timex.now(), days: -3))
    #   late_assessments = build_assessments_starting_at(Timex.shift(Timex.now(), days: -1))

    #   for assessment <- early_assessments ++ late_assessments do
    #     insert(:submission, %{student: user, assessment: assessment, status: :attempted})
    #   end

    #   resp_story =
    #     conn
    #     |> get("/v2/user")
    #     |> json_response(200)
    #     |> Map.get("story")

    #   expected_story = %{
    #     "story" => late_assessments |> List.first() |> Map.get(:story),
    #     "playStory" => false
    #   }

    #   assert resp_story == expected_story
    # end

    # @tag authenticate: :staff
    # test "success, staff", %{conn: conn} do
    #   user = conn.assigns.current_user

    #   resp =
    #     conn
    #     |> get("/v2/user")
    #     |> json_response(200)
    #     |> Map.delete("story")

    #   expected = %{
    #     "name" => user.name,
    #     "role" => "#{user.role}",
    #     "group" => nil,
    #     "grade" => 0,
    #     "maxGrade" => 0,
    #     "xp" => 0,
    #     "gameStates" => %{},
    #     "userId" => user.id
    #   }

    #   assert expected == resp
    # end

    test "unauthorized", %{conn: conn} do
      conn = get(conn, "/v2/user", nil)
      assert response(conn, 401) =~ "Unauthorised"
    end

    # defp build_assessments_starting_at(time) do
    #   type_order_map =
    #     Assessment.assessment_types()
    #     |> Enum.with_index()
    #     |> Enum.reduce(%{}, fn {type, idx}, acc -> Map.put(acc, type, idx) end)

    #   Assessment.assessment_types()
    #   |> Enum.map(
    #     &build(:assessment, %{
    #       type: &1,
    #       is_published: true,
    #       open_at: time,
    #       close_at: Timex.shift(time, days: 10)
    #     })
    #   )
    #   |> Enum.shuffle()
    #   |> Enum.map(&insert(&1))
    #   |> Enum.sort(&(type_order_map[&1.type] < type_order_map[&2.type]))
    # end
  end

  describe "GET /v2/user/latest_viewed" do
    @tag authenticate: :student
    test "success, student non-story fields", %{conn: conn} do
      user = conn.assigns.current_user
      course = user.latest_viewed
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
        submission: not_submitted_submission,
      )

      resp =
        conn
        |> get("/v2/user/latest_viewed")
        |> json_response(200)
        |> put_in(["courseRegistration", "story"], nil)

      expected = %{
        "courseRegistration" => %{
          "courseId" => course.id,
          "role" => "#{cr.role}",
          "group" => nil,
          "xp" => 110,
          "maxXp" => question.max_xp,
          "gameStates" => %{},
          "story" => nil
        },
        "courseConfiguration" => %{
          "assessmentTypes" => [],
          "enableAchievements" => true,
          "enableGame" => true,
          "enableSourcecast" => true,
          "courseShortName" => "CS1101S",
          "moduleHelpText" => "Help Text",
          "courseName" => "Programming Methodology",
          "sourceChapter" => 1,
          "sourceVariant" => "default",
          "viewable" => true
        }
      }

      assert expected == resp
    end

    @tag sign_in: %{latest_viewed: nil}
    test "success, no latest_viewed course", %{conn: conn} do
      resp =
        conn
        |> get("/v2/user/latest_viewed")
        |> json_response(200)

      expected = %{
        "courseRegistration" => nil,
        "courseConfiguration" => nil
      }

      assert expected == resp
    end

    test "unauthorized", %{conn: conn} do
      conn = get(conn, "/v2/user/latest_viewed", nil)
      assert response(conn, 401) =~ "Unauthorised"
    end
  end

  describe "PUT /v2/user/latest_viewed/{course_id}" do
    @tag authenticate: :student
    test "success, updating game state", %{conn: conn} do
      user = conn.assigns.current_user
      new_course = insert(:course)
      insert(:course_registration, %{user: user, course: new_course})

      conn
      |> put("/v2/user/latest_viewed/#{new_course.id}")
      |> response(200)

      updated_user = Repo.get(User, user.id)

      assert new_course.id == updated_user.latest_viewed_id
    end
  end

  describe "PUT /v2/course/{course_id}/user/game_states" do
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

  defp build_url(course_id), do: "/v2/course/#{course_id}/user"
end
