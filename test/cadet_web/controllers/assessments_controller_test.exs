defmodule CadetWeb.AssessmentsControllerTest do
  use CadetWeb.ConnCase
  use Timex

  import Ecto.Query
  import Mock

  alias Cadet.{Assessments, Repo}
  alias Cadet.Accounts.{Role, User}
  alias Cadet.Assessments.{Assessment, AssessmentType, Submission, SubmissionStatus}
  alias Cadet.Autograder.GradingJob
  alias CadetWeb.AssessmentsController

  setup do
    Cadet.Test.Seeds.assessments()
  end

  @xp_early_submission_max_bonus 100
  @xp_bonus_assessment_type ~w(mission sidequest)a

  test "swagger" do
    AssessmentsController.swagger_definitions()
    AssessmentsController.swagger_path_index(nil)
    AssessmentsController.swagger_path_show(nil)
    AssessmentsController.swagger_path_submit(nil)
  end

  describe "GET /, unauthenticated" do
    test "unauthorized", %{conn: conn} do
      conn = get(conn, build_url())
      assert response(conn, 401) =~ "Unauthorised"
    end
  end

  describe "GET /:assessment_id, unauthenticated" do
    test "unauthorized", %{conn: conn} do
      conn = get(conn, build_url(1))
      assert response(conn, 401) =~ "Unauthorised"
    end
  end

  # All roles should see almost the same overview
  describe "GET /, all roles" do
    test "renders assessments overview", %{conn: conn, users: users, assessments: assessments} do
      for {_role, user} <- users do
        expected =
          assessments
          |> Map.values()
          |> Enum.map(& &1.assessment)
          |> Enum.sort(&open_at_asc_comparator/2)
          |> Enum.map(
            &%{
              "id" => &1.id,
              "title" => &1.title,
              "shortSummary" => &1.summary_short,
              "story" => &1.story,
              "number" => &1.number,
              "reading" => &1.reading,
              "openAt" => format_datetime(&1.open_at),
              "closeAt" => format_datetime(&1.close_at),
              "type" => "#{&1.type}",
              "coverImage" => &1.cover_picture,
              "maxGrade" => 720,
              "maxXp" => 4500,
              "status" => get_assessment_status(user, &1),
              "gradingStatus" => "excluded"
            }
          )

        resp =
          conn
          |> sign_in(user)
          |> get(build_url())
          |> json_response(200)
          |> Enum.map(&Map.delete(&1, "xp"))
          |> Enum.map(&Map.delete(&1, "grade"))

        assert expected == resp
      end
    end

    test "does not render unpublished assessments", %{
      conn: conn,
      users: users,
      assessments: assessments
    } do
      for {_role, user} <- users do
        mission = assessments.mission

        {:ok, _} =
          mission.assessment
          |> Assessment.changeset(%{is_published: false})
          |> Repo.update()

        expected =
          assessments
          |> Map.delete(:mission)
          |> Map.values()
          |> Enum.map(fn a -> a.assessment end)
          |> Enum.sort(&open_at_asc_comparator/2)
          |> Enum.map(
            &%{
              "id" => &1.id,
              "title" => &1.title,
              "shortSummary" => &1.summary_short,
              "story" => &1.story,
              "number" => &1.number,
              "reading" => &1.reading,
              "openAt" => format_datetime(&1.open_at),
              "closeAt" => format_datetime(&1.close_at),
              "type" => "#{&1.type}",
              "coverImage" => &1.cover_picture,
              "maxGrade" => 720,
              "maxXp" => 4500,
              "status" => get_assessment_status(user, &1),
              "gradingStatus" => "excluded"
            }
          )

        resp =
          conn
          |> sign_in(user)
          |> get(build_url())
          |> json_response(200)
          |> Enum.map(&Map.delete(&1, "xp"))
          |> Enum.map(&Map.delete(&1, "grade"))

        assert expected == resp
      end
    end
  end

  describe "GET /, student only" do
    test "renders student submission status in overview", %{
      conn: conn,
      users: %{student: student},
      assessments: assessments
    } do
      assessment = assessments.mission.assessment
      [submission | _] = assessments.mission.submissions

      for status <- SubmissionStatus.__enum_map__() do
        submission
        |> Submission.changeset(%{status: status})
        |> Repo.update()

        resp =
          conn
          |> sign_in(student)
          |> get(build_url())
          |> json_response(200)
          |> Enum.find(&(&1["id"] == assessment.id))
          |> Map.get("status")

        assert get_assessment_status(student, assessment) == resp
      end
    end

    test "renders xp for students", %{
      conn: conn,
      users: %{student: student},
      assessments: assessments
    } do
      assessment = assessments.mission.assessment

      resp =
        conn
        |> sign_in(student)
        |> get(build_url())
        |> json_response(200)
        |> Enum.find(&(&1["id"] == assessment.id))
        |> Map.get("xp")

      assert resp == 1000 * 3 + 500 * 3
    end

    test "renders grade for students", %{
      conn: conn,
      users: %{student: student},
      assessments: assessments
    } do
      assessment = assessments.mission.assessment

      resp =
        conn
        |> sign_in(student)
        |> get(build_url())
        |> json_response(200)
        |> Enum.find(&(&1["id"] == assessment.id))
        |> Map.get("grade")

      assert resp == 200 * 3 + 40 * 3
    end
  end

  describe "GET /assessment_id, all roles" do
    test "it renders assessment details", %{
      conn: conn,
      users: users,
      assessments: assessments
    } do
      for role <- Role.__enum_map__() do
        user = Map.get(users, role)

        for {_type, %{assessment: assessment}} <- assessments do
          expected_assessments = %{
            "id" => assessment.id,
            "title" => assessment.title,
            "type" => "#{assessment.type}",
            "story" => assessment.story,
            "number" => assessment.number,
            "reading" => assessment.reading,
            "longSummary" => assessment.summary_long,
            "missionPDF" => Cadet.Assessments.Upload.url({assessment.mission_pdf, assessment})
          }

          resp_assessments =
            conn
            |> sign_in(user)
            |> get(build_url(assessment.id))
            |> json_response(200)
            |> Map.delete("questions")

          assert expected_assessments == resp_assessments
        end
      end
    end

    test "it renders assessment questions", %{
      conn: conn,
      users: users,
      assessments: assessments
    } do
      for role <- Role.__enum_map__() do
        user = Map.get(users, role)

        for {_type,
             %{
               assessment: assessment,
               mcq_questions: mcq_questions,
               programming_questions: programming_questions
             }} <- assessments do
          # Programming questions should come first due to seeding order
          expected_programming_questions =
            Enum.map(
              programming_questions,
              &%{
                "id" => &1.id,
                "type" => "#{&1.type}",
                "content" => &1.question.content,
                "solutionTemplate" => &1.question.template,
                "prepend" => &1.question.prepend,
                "postpend" => &1.question.postpend,
                "testcases" =>
                  Enum.map(
                    &1.question.public,
                    fn testcase ->
                      for {k, v} <- testcase, into: %{}, do: {Atom.to_string(k), v}
                    end
                  )
              }
            )

          expected_mcq_questions =
            Enum.map(
              mcq_questions,
              &%{
                "id" => &1.id,
                "type" => "#{&1.type}",
                "content" => &1.question.content,
                "choices" =>
                  Enum.map(
                    &1.question.choices,
                    fn choice ->
                      %{
                        "id" => choice.choice_id,
                        "content" => choice.content,
                        "hint" => choice.hint
                      }
                    end
                  )
              }
            )

          expected_questions = expected_programming_questions ++ expected_mcq_questions

          resp_questions =
            conn
            |> sign_in(user)
            |> get(build_url(assessment.id))
            |> json_response(200)
            |> Map.get("questions", [])
            |> Enum.map(&Map.delete(&1, "answer"))
            |> Enum.map(&Map.delete(&1, "solution"))
            |> Enum.map(&Map.delete(&1, "library"))
            |> Enum.map(&Map.delete(&1, "roomId"))
            |> Enum.map(&Map.delete(&1, "xp"))
            |> Enum.map(&Map.delete(&1, "grade"))
            |> Enum.map(&Map.delete(&1, "maxXp"))
            |> Enum.map(&Map.delete(&1, "maxGrade"))
            |> Enum.map(&Map.delete(&1, "grader"))
            |> Enum.map(&Map.delete(&1, "gradedAt"))
            |> Enum.map(&Map.delete(&1, "autogradingResults"))
            |> Enum.map(&Map.delete(&1, "autogradingStatus"))

          assert expected_questions == resp_questions
        end
      end
    end

    test "it renders assessment question libraries", %{
      conn: conn,
      users: users,
      assessments: assessments
    } do
      for role <- Role.__enum_map__() do
        user = Map.get(users, role)

        for {_type,
             %{
               assessment: assessment,
               mcq_questions: mcq_questions,
               programming_questions: programming_questions
             }} <- assessments do
          # Programming questions should come first due to seeding order

          expected_libraries =
            (programming_questions ++ mcq_questions)
            |> Enum.map(&Map.get(&1, :library))
            |> Enum.map(
              &%{
                "chapter" => &1.chapter,
                "globals" => &1.globals,
                "external" => %{
                  "name" => "#{&1.external.name}",
                  "symbols" => &1.external.symbols
                }
              }
            )

          resp_libraries =
            conn
            |> sign_in(user)
            |> get(build_url(assessment.id))
            |> json_response(200)
            |> Map.get("questions", [])
            |> Enum.map(&Map.get(&1, "library"))

          assert resp_libraries == expected_libraries
        end
      end
    end

    test "it renders solutions for ungraded assessments (path)", %{
      conn: conn,
      users: users,
      assessments: assessments
    } do
      for role <- Role.__enum_map__() do
        user = Map.get(users, role)

        %{
          assessment: assessment,
          mcq_questions: mcq_questions,
          programming_questions: programming_questions
        } = assessments.path

        # Seeds set solution as 0
        expected_mcq_solutions = Enum.map(mcq_questions, fn _ -> %{"solution" => 0} end)

        expected_programming_solutions =
          Enum.map(programming_questions, &%{"solution" => &1.question.solution})

        expected_solutions = Enum.sort(expected_mcq_solutions ++ expected_programming_solutions)

        resp_solutions =
          conn
          |> sign_in(user)
          |> get(build_url(assessment.id))
          |> json_response(200)
          |> Map.get("questions", [])
          |> Enum.map(&Map.take(&1, ["solution"]))
          |> Enum.sort()

        assert expected_solutions == resp_solutions
      end
    end

    test "it renders xp, grade for students", %{
      conn: conn,
      users: users,
      assessments: assessments
    } do
      for role <- Role.__enum_map__() do
        user = Map.get(users, role)

        for {_type,
             %{
               assessment: assessment,
               mcq_answers: [mcq_answers | _],
               programming_answers: [programming_answers | _]
             }} <- assessments do
          expected =
            if role == :student do
              Enum.map(
                programming_answers ++ mcq_answers,
                &%{
                  "xp" => &1.xp + &1.xp_adjustment,
                  "grade" => &1.grade + &1.adjustment
                }
              )
            else
              fn -> %{"xp" => 0, "grade" => 0} end
              |> Stream.repeatedly()
              |> Enum.take(length(programming_answers) + length(mcq_answers))
            end

          resp =
            conn
            |> sign_in(user)
            |> get(build_url(assessment.id))
            |> json_response(200)
            |> Map.get("questions", [])
            |> Enum.map(&Map.take(&1, ~w(xp grade)))

          assert expected == resp
        end
      end
    end

    test "it does not render solutions for ungraded assessments (path)", %{
      conn: conn,
      users: users,
      assessments: assessments
    } do
      for role <- Role.__enum_map__() do
        user = Map.get(users, role)

        for {_type,
             %{
               assessment: assessment
             }} <- Map.delete(assessments, :path) do
          resp_solutions =
            conn
            |> sign_in(user)
            |> get(build_url(assessment.id))
            |> json_response(200)
            |> Map.get("questions", [])
            |> Enum.map(&Map.get(&1, ["solution"]))

          assert Enum.uniq(resp_solutions) == [nil]
        end
      end
    end

    test "it does not permit access to unpublished assessments", %{
      conn: conn,
      users: users,
      assessments: %{mission: mission}
    } do
      for role <- Role.__enum_map__() do
        user = Map.get(users, role)

        {:ok, _} =
          mission.assessment
          |> Assessment.changeset(%{is_published: false})
          |> Repo.update()

        conn =
          conn
          |> sign_in(user)
          |> get(build_url(mission.assessment.id))

        assert response(conn, 400) == "Assessment not found"
      end
    end
  end

  describe "GET /assessment_id, student" do
    test "it renders previously submitted answers", %{
      conn: conn,
      users: %{student: student},
      assessments: assessments
    } do
      for {_type,
           %{
             assessment: assessment,
             mcq_answers: [mcq_answers | _],
             programming_answers: [programming_answers | _]
           }} <- assessments do
        # Programming questions should come first due to seeding order

        expected_programming_answers =
          Enum.map(programming_answers, &%{"answer" => &1.answer.code})

        expected_mcq_answers = Enum.map(mcq_answers, &%{"answer" => &1.answer.choice_id})
        expected_answers = expected_programming_answers ++ expected_mcq_answers

        resp_answers =
          conn
          |> sign_in(student)
          |> get(build_url(assessment.id))
          |> json_response(200)
          |> Map.get("questions", [])
          |> Enum.map(&Map.take(&1, ["answer"]))

        assert expected_answers == resp_answers
      end
    end

    test "it renders roomId", %{
      conn: conn,
      users: %{student: student},
      assessments: assessments
    } do
      for {_type,
           %{
             assessment: assessment,
             mcq_answers: [mcq_answers | _],
             programming_answers: [programming_answers | _]
           }} <- assessments do
        # Programming questions should come first due to seeding order
        expected_room_id =
          Enum.map(programming_answers ++ mcq_answers, &%{"roomId" => &1.room_id})

        resp_room_id =
          conn
          |> sign_in(student)
          |> get(build_url(assessment.id))
          |> json_response(200)
          |> Map.get("questions", [])
          |> Enum.map(&Map.take(&1, ["roomId"]))

        assert expected_room_id == resp_room_id
      end
    end

    test "it does not permit access to not yet open assessments", %{
      conn: conn,
      users: %{student: student},
      assessments: %{mission: mission}
    } do
      mission.assessment
      |> Assessment.changeset(%{
        open_at: Timex.shift(Timex.now(), days: 5),
        close_at: Timex.shift(Timex.now(), days: 10)
      })
      |> Repo.update!()

      conn =
        conn
        |> sign_in(student)
        |> get(build_url(mission.assessment.id))

      assert response(conn, 401) == "Assessment not open"
    end
  end

  describe "GET /assessment_id, non-students" do
    test "it renders empty answers", %{
      conn: conn,
      users: users,
      assessments: assessments
    } do
      for role <- ~w(staff admin)a do
        user = Map.get(users, role)

        for {_type, %{assessment: assessment}} <- assessments do
          resp_answers =
            conn
            |> sign_in(user)
            |> get(build_url(assessment.id))
            |> json_response(200)
            |> Map.get("questions", [])
            |> Enum.map(&Map.get(&1, ["answer"]))

          assert Enum.uniq(resp_answers) == [nil]
        end
      end
    end

    test "it permits access to not yet open assessments", %{
      conn: conn,
      users: users,
      assessments: %{mission: mission}
    } do
      for role <- ~w(staff admin)a do
        user = Map.get(users, role)

        mission.assessment
        |> Assessment.changeset(%{
          open_at: Timex.shift(Timex.now(), days: 5),
          close_at: Timex.shift(Timex.now(), days: 10)
        })
        |> Repo.update!()

        resp =
          conn
          |> sign_in(user)
          |> get(build_url(mission.assessment.id))
          |> json_response(200)

        assert resp["id"] == mission.assessment.id
      end
    end
  end

  describe "POST /assessment_id/submit unauthenticated" do
    test "is not permitted", %{conn: conn, assessments: %{mission: %{assessment: assessment}}} do
      conn = post(conn, build_url_submit(assessment.id))
      assert response(conn, 401) == "Unauthorised"
    end
  end

  describe "POST /assessment_id/submit non-students" do
    for role <- [:staff, :admin] do
      @tag authenticate: role
      test "is not permitted for #{role}", %{
        conn: conn,
        assessments: %{mission: %{assessment: assessment}}
      } do
        conn = post(conn, build_url_submit(assessment.id))
        assert response(conn, 403) == "User is not permitted to answer questions"
      end
    end
  end

  describe "POST /assessment_id/submit students" do
    test "is successful for attempted assessments", %{
      conn: conn,
      assessments: %{mission: %{assessment: assessment}}
    } do
      with_mock GradingJob,
        force_grade_individual_submission: fn _ -> nil end do
        user = insert(:user, %{role: :student})

        submission =
          insert(:submission, %{student: user, assessment: assessment, status: :attempted})

        conn =
          conn
          |> sign_in(user)
          |> post(build_url_submit(assessment.id))

        assert response(conn, 200) == "OK"

        # Preloading is necessary because Mock does an exact match, including metadata
        submission_db = Submission |> Repo.get(submission.id) |> Repo.preload(:assessment)

        assert submission_db.status == :submitted

        assert_called(GradingJob.force_grade_individual_submission(submission_db))
      end
    end

    test "submission of answer within 2 days of opening grants full XP bonus", %{conn: conn} do
      with_mock GradingJob, force_grade_individual_submission: fn _ -> nil end do
        for type <- @xp_bonus_assessment_type do
          assessment =
            insert(
              :assessment,
              open_at: Timex.shift(Timex.now(), hours: -40),
              close_at: Timex.shift(Timex.now(), days: 7),
              is_published: true,
              type: type
            )

          question = insert(:programming_question, assessment: assessment)
          user = insert(:user, role: :student)

          submission =
            insert(:submission, assessment: assessment, student: user, status: :attempted)

          insert(
            :answer,
            submission: submission,
            question: question,
            answer: %{code: "f => f(f);"}
          )

          conn
          |> sign_in(user)
          |> post(build_url_submit(assessment.id))
          |> response(200)

          submission_db = Repo.get(Submission, submission.id)

          assert submission_db.status == :submitted
          assert submission_db.xp_bonus == @xp_early_submission_max_bonus
        end
      end
    end

    test "submission of answer after 2 days within the next 100 hours of opening grants decaying XP bonus",
         %{conn: conn} do
      with_mock GradingJob, force_grade_individual_submission: fn _ -> nil end do
        for hours_after <- 48..148,
            type <- @xp_bonus_assessment_type do
          assessment =
            insert(
              :assessment,
              open_at: Timex.shift(Timex.now(), hours: -hours_after),
              close_at: Timex.shift(Timex.now(), hours: 500),
              is_published: true,
              type: type
            )

          question = insert(:programming_question, assessment: assessment)
          user = insert(:user, role: :student)

          submission =
            insert(:submission, assessment: assessment, student: user, status: :attempted)

          insert(
            :answer,
            submission: submission,
            question: question,
            answer: %{code: "f => f(f);"}
          )

          conn
          |> sign_in(user)
          |> post(build_url_submit(assessment.id))
          |> response(200)

          submission_db = Repo.get(Submission, submission.id)

          assert submission_db.status == :submitted
          assert submission_db.xp_bonus == @xp_early_submission_max_bonus - (hours_after - 48)
        end
      end
    end

    test "submission of answer after 2 days and after the next 100 hours yield 0 XP bonus", %{
      conn: conn
    } do
      with_mock GradingJob, force_grade_individual_submission: fn _ -> nil end do
        for type <- @xp_bonus_assessment_type do
          assessment =
            insert(
              :assessment,
              open_at: Timex.shift(Timex.now(), hours: -150),
              close_at: Timex.shift(Timex.now(), days: 7),
              is_published: true,
              type: type
            )

          question = insert(:programming_question, assessment: assessment)
          user = insert(:user, role: :student)

          submission =
            insert(:submission, assessment: assessment, student: user, status: :attempted)

          insert(
            :answer,
            submission: submission,
            question: question,
            answer: %{code: "f => f(f);"}
          )

          conn
          |> sign_in(user)
          |> post(build_url_submit(assessment.id))
          |> response(200)

          submission_db = Repo.get(Submission, submission.id)

          assert submission_db.status == :submitted
          assert submission_db.xp_bonus == 0
        end
      end
    end

    test "does not give bonus for non-bonus eligible assessment types", %{conn: conn} do
      with_mock GradingJob, force_grade_individual_submission: fn _ -> nil end do
        non_eligible_types =
          Enum.filter(AssessmentType.__enum_map__(), &(&1 not in @xp_bonus_assessment_type))

        for hours_after <- 0..148,
            type <- non_eligible_types do
          assessment =
            insert(
              :assessment,
              open_at: Timex.shift(Timex.now(), hours: -hours_after),
              close_at: Timex.shift(Timex.now(), days: 7),
              is_published: true,
              type: type
            )

          question = insert(:programming_question, assessment: assessment)
          user = insert(:user, role: :student)

          submission =
            insert(:submission, assessment: assessment, student: user, status: :attempted)

          insert(
            :answer,
            submission: submission,
            question: question,
            answer: %{code: "f => f(f);"}
          )

          conn
          |> sign_in(user)
          |> post(build_url_submit(assessment.id))
          |> response(200)

          submission_db = Repo.get(Submission, submission.id)

          assert submission_db.status == :submitted
          assert submission_db.xp_bonus == 0
        end
      end
    end

    # This also covers unpublished and assessments that are not open yet since they cannot be
    # answered.
    test "is not permitted for unattempted assessments", %{
      conn: conn,
      assessments: %{mission: %{assessment: assessment}}
    } do
      user = insert(:user, %{role: :student})

      conn =
        conn
        |> sign_in(user)
        |> post(build_url_submit(assessment.id))

      assert response(conn, 404) == "Submission not found"
    end

    test "is not permitted for incomplete assessments", %{
      conn: conn,
      assessments: %{mission: %{assessment: assessment}}
    } do
      user = insert(:user, %{role: :student})
      insert(:submission, %{student: user, assessment: assessment, status: :attempting})

      conn =
        conn
        |> sign_in(user)
        |> post(build_url_submit(assessment.id))

      assert response(conn, 400) == "Some questions have not been attempted"
    end

    test "is not permitted for already submitted assessments", %{
      conn: conn,
      assessments: %{mission: %{assessment: assessment}}
    } do
      user = insert(:user, %{role: :student})
      insert(:submission, %{student: user, assessment: assessment, status: :submitted})

      conn =
        conn
        |> sign_in(user)
        |> post(build_url_submit(assessment.id))

      assert response(conn, 403) == "Assessment has already been submitted"
    end

    test "is not permitted for closed assessments", %{conn: conn} do
      user = insert(:user, %{role: :student})

      # Only check for after-closing because submission shouldn't exist if unpublished or
      # before opening and would fall under "Submission not found"
      after_close_at_assessment =
        insert(:assessment, %{
          open_at: Timex.shift(Timex.now(), days: -10),
          close_at: Timex.shift(Timex.now(), days: -5)
        })

      insert(:submission, %{
        student: user,
        assessment: after_close_at_assessment,
        status: :attempted
      })

      conn =
        conn
        |> sign_in(user)
        |> post(build_url_submit(after_close_at_assessment.id))

      assert response(conn, 403) == "Assessment not open"
    end
  end

  test "grading status is updated when assessment is graded", %{
    conn: conn,
    users: %{staff: avenger}
  } do
    assessment =
      insert(
        :assessment,
        open_at: Timex.shift(Timex.now(), hours: -2),
        close_at: Timex.shift(Timex.now(), days: 7),
        is_published: true,
        type: :mission
      )

    [question_one, question_two] = insert_list(2, :programming_question, assessment: assessment)

    user = insert(:user, role: :student)

    submission = insert(:submission, assessment: assessment, student: user, status: :submitted)

    Enum.each(
      [question_one, question_two],
      &insert(:answer, submission: submission, question: &1, answer: %{code: "f => f(f);"})
    )

    get_grading_status = fn ->
      conn
      |> sign_in(user)
      |> get(build_url())
      |> json_response(200)
      |> Enum.find(&(&1["id"] == assessment.id))
      |> Map.get("gradingStatus")
    end

    grade_question = fn question ->
      Assessments.update_grading_info(
        %{submission_id: submission.id, question_id: question.id},
        %{"adjustment" => 0},
        avenger
      )
    end

    assert get_grading_status.() == "none"

    grade_question.(question_one)

    assert get_grading_status.() == "grading"

    grade_question.(question_two)

    assert get_grading_status.() == "graded"
  end

  defp build_url, do: "/v1/assessments/"
  defp build_url(assessment_id), do: "/v1/assessments/#{assessment_id}"
  defp build_url_submit(assessment_id), do: "/v1/assessments/#{assessment_id}/submit"

  defp open_at_asc_comparator(x, y), do: Timex.before?(x.open_at, y.open_at)

  defp get_assessment_status(user = %User{}, assessment = %Assessment{}) do
    submission =
      Submission
      |> where(student_id: ^user.id)
      |> where(assessment_id: ^assessment.id)
      |> Repo.one()

    (submission && submission.status |> Atom.to_string()) || "not_attempted"
  end
end
