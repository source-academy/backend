defmodule CadetWeb.AssessmentsControllerTest do
  use CadetWeb.ConnCase
  use Timex

  import Ecto.Query
  import ExUnit.CaptureLog
  import Mock

  alias Cadet.{Assessments, Repo}
  alias Cadet.Accounts.{Role, User}
  alias Cadet.Assessments.{Assessment, AssessmentType, Submission, SubmissionStatus}
  alias Cadet.Autograder.GradingJob
  alias Cadet.Test.XMLGenerator
  alias CadetWeb.AssessmentsController

  @local_name "test/fixtures/local_repo"

  setup do
    File.rm_rf!(@local_name)

    on_exit(fn ->
      File.rm_rf!(@local_name)
    end)

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

  describe "POST /:assessment_id, unauthenticated" do
    test "unauthorized", %{conn: conn} do
      conn = post(conn, build_url(1))
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
              "private" => false,
              "isPublished" => &1.is_published,
              "gradedCount" => 0,
              "questionCount" => 6
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

    test "render password protected assessments properly", %{
      conn: conn,
      users: users,
      assessments: assessments
    } do
      for {_role, user} <- users do
        mission = assessments.mission

        {:ok, _} =
          mission.assessment
          |> Assessment.changeset(%{password: "mysupersecretpassword"})
          |> Repo.update()

        resp =
          conn
          |> sign_in(user)
          |> get(build_url())
          |> json_response(200)
          |> Enum.find(&(&1["type"] == "mission"))
          |> Map.get("private")

        assert resp == true
      end
    end
  end

  describe "GET /, student only" do
    test "does not render unpublished assessments", %{
      conn: conn,
      users: %{student: student},
      assessments: assessments
    } do
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
            "status" => get_assessment_status(student, &1),
            "private" => false,
            "isPublished" => &1.is_published,
            "gradedCount" => 0,
            "questionCount" => 6
          }
        )

      resp =
        conn
        |> sign_in(student)
        |> get(build_url())
        |> json_response(200)
        |> Enum.map(&Map.delete(&1, "xp"))
        |> Enum.map(&Map.delete(&1, "grade"))

      assert expected == resp
    end

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

  describe "GET /, non-students" do
    test "renders unpublished assessments", %{
      conn: conn,
      users: users,
      assessments: assessments
    } do
      for role <- ~w(staff admin)a do
        user = Map.get(users, role)
        mission = assessments.mission

        {:ok, _} =
          mission.assessment
          |> Assessment.changeset(%{is_published: false})
          |> Repo.update()

        resp =
          conn
          |> sign_in(user)
          |> get(build_url())
          |> json_response(200)
          |> Enum.map(&Map.delete(&1, "xp"))
          |> Enum.map(&Map.delete(&1, "grade"))

        expected =
          assessments
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
              "private" => false,
              "gradedCount" => 0,
              "questionCount" => 6,
              "isPublished" =>
                if &1.type == :mission do
                  false
                else
                  &1.is_published
                end
            }
          )

        assert expected == resp
      end
    end
  end

  describe "POST /assessment_id, all roles" do
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
            |> post(build_url(assessment.id))
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
                "postpend" =>
                  if assessment.type == :path do
                    &1.question.postpend
                  else
                    ""
                  end,
                "testcases" =>
                  Enum.map(
                    &1.question.public,
                    fn testcase ->
                      for {k, v} <- testcase,
                          into: %{"type" => "public"},
                          do: {Atom.to_string(k), v}
                    end
                  ) ++
                    if assessment.type == :path do
                      Enum.map(
                        &1.question.private,
                        fn testcase ->
                          for {k, v} <- testcase,
                              into: %{"type" => "hidden"},
                              do: {Atom.to_string(k), v}
                        end
                      )
                    else
                      []
                    end
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
            |> post(build_url(assessment.id))
            |> json_response(200)
            |> Map.get("questions", [])
            |> Enum.map(&Map.delete(&1, "answer"))
            |> Enum.map(&Map.delete(&1, "solution"))
            |> Enum.map(&Map.delete(&1, "library"))
            |> Enum.map(&Map.delete(&1, "xp"))
            |> Enum.map(&Map.delete(&1, "grade"))
            |> Enum.map(&Map.delete(&1, "maxXp"))
            |> Enum.map(&Map.delete(&1, "maxGrade"))
            |> Enum.map(&Map.delete(&1, "grader"))
            |> Enum.map(&Map.delete(&1, "gradedAt"))
            |> Enum.map(&Map.delete(&1, "autogradingResults"))
            |> Enum.map(&Map.delete(&1, "autogradingStatus"))
            |> Enum.map(&Map.delete(&1, "comments"))

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
            |> post(build_url(assessment.id))
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
          |> post(build_url(assessment.id))
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
            |> post(build_url(assessment.id))
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
            |> post(build_url(assessment.id))
            |> json_response(200)
            |> Map.get("questions", [])
            |> Enum.map(&Map.get(&1, ["solution"]))

          assert Enum.uniq(resp_solutions) == [nil]
        end
      end
    end
  end

  describe "POST /assessment_id, student" do
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
          |> post(build_url(assessment.id))
          |> json_response(200)
          |> Map.get("questions", [])
          |> Enum.map(&Map.take(&1, ["answer"]))

        assert expected_answers == resp_answers
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
        |> post(build_url(mission.assessment.id))

      assert response(conn, 401) == "Assessment not open"
    end

    test "it does not permit access to unpublished assessments", %{
      conn: conn,
      users: %{student: student},
      assessments: %{mission: mission}
    } do
      {:ok, _} =
        mission.assessment
        |> Assessment.changeset(%{is_published: false})
        |> Repo.update()

      conn =
        conn
        |> sign_in(student)
        |> post(build_url(mission.assessment.id))

      assert response(conn, 400) == "Assessment not found"
    end
  end

  describe "POST /assessment_id, non-students" do
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
            |> post(build_url(assessment.id))
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
          |> post(build_url(mission.assessment.id))
          |> json_response(200)

        assert resp["id"] == mission.assessment.id
      end
    end

    test "it permits access to unpublished assessments", %{
      conn: conn,
      users: users,
      assessments: %{mission: mission}
    } do
      for role <- ~w(staff admin)a do
        user = Map.get(users, role)

        {:ok, _} =
          mission.assessment
          |> Assessment.changeset(%{is_published: false})
          |> Repo.update()

        resp =
          conn
          |> sign_in(user)
          |> post(build_url(mission.assessment.id))
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
        group = insert(:group)
        user = insert(:user, %{role: :student, group: group})

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

          group = insert(:group)
          user = insert(:user, %{role: :student, group: group})

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

          group = insert(:group)
          user = insert(:user, %{role: :student, group: group})

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

          group = insert(:group)
          user = insert(:user, %{role: :student, group: group})

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

          group = insert(:group)
          user = insert(:user, %{role: :student, group: group})

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

  test "graded count is updated when assessment is graded", %{
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

    get_graded_count = fn ->
      conn
      |> sign_in(user)
      |> get(build_url())
      |> json_response(200)
      |> Enum.find(&(&1["id"] == assessment.id))
      |> Map.get("gradedCount")
    end

    grade_question = fn question ->
      Assessments.update_grading_info(
        %{submission_id: submission.id, question_id: question.id},
        %{"adjustment" => 0},
        avenger
      )
    end

    assert get_graded_count.() == 0

    grade_question.(question_one)

    assert get_graded_count.() == 1

    grade_question.(question_two)

    assert get_graded_count.() == 2
  end

  describe "Password protected assessments render properly" do
    test "returns 403 when trying to access a password protected assessment without a password",
         %{
           conn: conn,
           users: users
         } do
      assessment = insert(:assessment, %{type: "practical", is_published: true})

      assessment
      |> Assessment.changeset(%{
        password: "mysupersecretpassword",
        open_at: Timex.shift(Timex.now(), days: -2),
        close_at: Timex.shift(Timex.now(), days: +1)
      })
      |> Repo.update!()

      for {_role, user} <- users do
        conn = conn |> sign_in(user) |> post(build_url(assessment.id))
        assert response(conn, 403) == "Missing Password."
      end
    end

    test "returns 403 when password is wrong/invalid", %{
      conn: conn,
      users: users
    } do
      assessment = insert(:assessment, %{type: "practical", is_published: true})

      assessment
      |> Assessment.changeset(%{
        password: "mysupersecretpassword",
        open_at: Timex.shift(Timex.now(), days: -2),
        close_at: Timex.shift(Timex.now(), days: +1)
      })
      |> Repo.update!()

      for {_role, user} <- users do
        conn =
          conn
          |> sign_in(user)
          |> post(build_url(assessment.id), %{:password => "wrong"})

        assert response(conn, 403) == "Invalid Password."
      end
    end

    test "allow users with preexisting submission to access private assessment without a password",
         %{
           conn: conn,
           users: %{student: student}
         } do
      assessment = insert(:assessment, %{type: "practical", is_published: true})

      assessment
      |> Assessment.changeset(%{
        password: "mysupersecretpassword",
        open_at: Timex.shift(Timex.now(), days: -2),
        close_at: Timex.shift(Timex.now(), days: +1)
      })
      |> Repo.update!()

      insert(:submission, %{assessment: assessment, student: student})
      conn = conn |> sign_in(student) |> post(build_url(assessment.id))
      assert response(conn, 200)
    end

    test "ignore password when assessment is not password protected", %{
      conn: conn,
      users: users,
      assessments: assessments
    } do
      assessment = assessments.mission.assessment

      for {_role, user} <- users do
        conn =
          conn
          |> sign_in(user)
          |> post(build_url(assessment.id), %{:password => "wrong"})
          |> json_response(200)

        assert conn["id"] == assessment.id
      end
    end

    test "render assessment when password is correct", %{
      conn: conn,
      users: users,
      assessments: assessments
    } do
      assessment = assessments.mission.assessment

      {:ok, _} =
        assessment
        |> Assessment.changeset(%{password: "mysupersecretpassword"})
        |> Repo.update()

      for {_role, user} <- users do
        conn =
          conn
          |> sign_in(user)
          |> post(build_url(assessment.id), %{:password => "mysupersecretpassword"})
          |> json_response(200)

        assert conn["id"] == assessment.id
      end
    end

    test "permit global access to private assessment after closed", %{
      conn: conn,
      users: %{student: student},
      assessments: %{mission: mission}
    } do
      mission.assessment
      |> Assessment.changeset(%{
        open_at: Timex.shift(Timex.now(), days: -2),
        close_at: Timex.shift(Timex.now(), days: -1)
      })
      |> Repo.update!()

      conn =
        conn
        |> sign_in(student)
        |> post(build_url(mission.assessment.id))

      assert response(conn, 200)
    end
  end

  describe "POST /, unauthenticated" do
    test "unauthorized", %{conn: conn} do
      assessment = build(:assessment, type: :mission, is_published: true)
      questions = build_list(5, :question, assessment: nil)
      xml = XMLGenerator.generate_xml_for(assessment, questions)
      file = File.write("test/fixtures/local_repo/test.xml", xml)
      force_update = "false"
      body = %{assessment: file, forceUpdate: force_update}
      conn = post(conn, build_url(), body)
      assert response(conn, 401) =~ "Unauthorised"
    end
  end

  describe "POST /, student only" do
    @tag authenticate: :student
    test "unauthorized", %{conn: conn} do
      assessment = build(:assessment, type: :mission, is_published: true)
      questions = build_list(5, :question, assessment: nil)
      xml = XMLGenerator.generate_xml_for(assessment, questions)
      force_update = "false"
      body = %{assessment: xml, forceUpdate: force_update}
      conn = post(conn, build_url(), body)
      assert response(conn, 403) == "User not allowed to create assessment"
    end
  end

  describe "POST /, staff only" do
    @tag authenticate: :staff
    test "successful", %{conn: conn} do
      assessment = build(:assessment, type: :mission, is_published: true)
      questions = build_list(5, :question, assessment: nil)

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

      body = %{assessment: %{file: formdata}, forceUpdate: force_update}
      conn = post(conn, build_url(), body)
      number = assessment.number

      expected_assessment =
        Assessment
        |> where(number: ^number)
        |> Repo.one()

      assert response(conn, 200) == "OK"
      assert expected_assessment != nil
    end

    @tag authenticate: :staff
    test "upload empty xml", %{conn: conn} do
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

      body = %{assessment: %{file: formdata}, forceUpdate: force_update}

      err_msg =
        "Invalid XML fatal expected_element_start_tag file file_name_unknown line 1 col 1 "

      assert capture_log(fn ->
               conn = post(conn, build_url(), body)
               assert(response(conn, 400) == err_msg)
             end) =~ ~r/.*fatal: :expected_element_start_tag.*/
    end
  end

  describe "DELETE /:assessment_id, unauthenticated" do
    test "unauthorized", %{conn: conn} do
      assessment = insert(:assessment)
      conn = delete(conn, build_url(assessment.id))
      assert response(conn, 401) =~ "Unauthorised"
    end
  end

  describe "DELETE /:assessment_id, student only" do
    @tag authenticate: :student
    test "unauthorized", %{conn: conn} do
      assessment = insert(:assessment)
      conn = delete(conn, build_url(assessment.id))
      assert response(conn, 403) == "User is not permitted to delete"
    end
  end

  describe "DELETE /:assessment_id, staff only" do
    @tag authenticate: :staff
    test "successful", %{conn: conn} do
      assessment = insert(:assessment)
      conn = delete(conn, build_url(assessment.id))
      assert response(conn, 200) == "OK"
      assert Repo.get(Assessment, assessment.id) == nil
    end
  end

  describe "POST /publish/:assessment_id, unauthenticated" do
    test "unauthorized", %{conn: conn} do
      assessment = insert(:assessment)
      conn = post(conn, build_url_publish(assessment.id))
      assert response(conn, 401) =~ "Unauthorised"
    end
  end

  describe "POST /publish/:assessment_id, student only" do
    @tag authenticate: :student
    test "forbidden", %{conn: conn} do
      assessment = insert(:assessment)
      conn = post(conn, build_url_publish(assessment.id))
      assert response(conn, 403) == "User is not permitted to publish"
    end
  end

  describe "POST /publish/:assessment_id, staff only" do
    @tag authenticate: :staff
    test "successful toggle from published to unpublished", %{conn: conn} do
      assessment = insert(:assessment, is_published: true)
      conn = post(conn, build_url_publish(assessment.id))
      expected = Repo.get(Assessment, assessment.id).is_published
      assert response(conn, 200) == "OK"
      assert expected == false
    end

    @tag authenticate: :staff
    test "successful toggle from unpublished to published", %{conn: conn} do
      assessment = insert(:assessment, is_published: false)
      conn = post(conn, build_url_publish(assessment.id))
      expected = Repo.get(Assessment, assessment.id).is_published
      assert response(conn, 200) == "OK"
      assert expected == true
    end
  end

  describe "POST /update/:assessment_id, unauthenticated" do
    test "unauthorized", %{conn: conn} do
      assessment = insert(:assessment)
      conn = post(conn, build_url_update(assessment.id))
      assert response(conn, 401) =~ "Unauthorised"
    end
  end

  describe "POST /update/:assessment_id, student only" do
    @tag authenticate: :student
    test "forbidden", %{conn: conn} do
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
      assessment = insert(:assessment)
      conn = post(conn, build_url_update(assessment.id), new_dates)
      assert response(conn, 403) == "User is not permitted to edit"
    end
  end

  describe "POST /update/:assessment_id, staff only" do
    @tag authenticate: :staff
    test "successful", %{conn: conn} do
      open_at =
        Timex.now()
        |> Timex.beginning_of_day()
        |> Timex.shift(days: 3)
        |> Timex.shift(hours: 4)

      close_at = Timex.shift(open_at, days: 7)
      assessment = insert(:assessment, %{open_at: open_at, close_at: close_at})

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
        |> post(build_url_update(assessment.id), new_dates)

      assessment = Repo.get(Assessment, assessment.id)
      assert response(conn, 200) == "OK"
      assert [assessment.open_at, assessment.close_at] == [new_open_at, new_close_at]
    end

    @tag authenticate: :staff
    test "allowed to change open time of opened assessments", %{conn: conn} do
      open_at =
        Timex.now()
        |> Timex.beginning_of_day()
        |> Timex.shift(days: -3)
        |> Timex.shift(hours: 4)

      close_at = Timex.shift(open_at, days: 7)
      assessment = insert(:assessment, %{open_at: open_at, close_at: close_at})

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
        |> post(build_url_update(assessment.id), new_dates)

      assessment = Repo.get(Assessment, assessment.id)
      assert response(conn, 200) == "OK"
      assert [assessment.open_at, assessment.close_at] == [new_open_at, close_at]
    end

    @tag authenticate: :staff
    test "not allowed to set close time to before open time", %{conn: conn} do
      open_at =
        Timex.now()
        |> Timex.beginning_of_day()
        |> Timex.shift(days: 3)
        |> Timex.shift(hours: 4)

      close_at = Timex.shift(open_at, days: 7)
      assessment = insert(:assessment, %{open_at: open_at, close_at: close_at})

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
        |> post(build_url_update(assessment.id), new_dates)

      assessment = Repo.get(Assessment, assessment.id)
      assert response(conn, 400) == "New end date should occur after new opening date"
      assert [assessment.open_at, assessment.close_at] == [open_at, close_at]
    end

    @tag authenticate: :staff
    test "successful, set close time to before current time", %{conn: conn} do
      open_at =
        Timex.now()
        |> Timex.beginning_of_day()
        |> Timex.shift(days: -3)
        |> Timex.shift(hours: 4)

      close_at = Timex.shift(open_at, days: 7)
      assessment = insert(:assessment, %{open_at: open_at, close_at: close_at})

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
        |> post(build_url_update(assessment.id), new_dates)

      assessment = Repo.get(Assessment, assessment.id)
      assert response(conn, 200) == "OK"
      assert [assessment.open_at, assessment.close_at] == [open_at, new_close_at]
    end

    @tag authenticate: :staff
    test "successful, set open time to before current time", %{conn: conn} do
      open_at =
        Timex.now()
        |> Timex.beginning_of_day()
        |> Timex.shift(days: 3)
        |> Timex.shift(hours: 4)

      close_at = Timex.shift(open_at, days: 7)
      assessment = insert(:assessment, %{open_at: open_at, close_at: close_at})

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
        |> post(build_url_update(assessment.id), new_dates)

      assessment = Repo.get(Assessment, assessment.id)
      assert response(conn, 200) == "OK"
      assert [assessment.open_at, assessment.close_at] == [new_open_at, close_at]
    end
  end

  defp build_url, do: "/v1/assessments/"
  defp build_url(assessment_id), do: "/v1/assessments/#{assessment_id}"
  defp build_url_submit(assessment_id), do: "/v1/assessments/#{assessment_id}/submit"
  defp build_url_publish(assessment_id), do: "/v1/assessments/publish/#{assessment_id}"
  defp build_url_update(assessment_id), do: "/v1/assessments/update/#{assessment_id}"

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
