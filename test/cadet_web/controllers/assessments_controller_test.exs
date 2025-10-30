defmodule CadetWeb.AssessmentsControllerTest do
  use CadetWeb.ConnCase
  use Timex

  import Ecto.Query
  import Mock

  alias Cadet.{Assessments, Repo}
  alias Cadet.Accounts.{Role, CourseRegistration}
  alias Cadet.Assessments.{Assessment, Submission, SubmissionStatus}
  alias Cadet.Autograder.GradingJob
  alias CadetWeb.AssessmentsController

  @local_name "test/fixtures/local_repo"

  setup do
    File.rm_rf!(@local_name)

    on_exit(fn ->
      File.rm_rf!(@local_name)
    end)

    Cadet.Test.Seeds.assessments()
  end

  test "swagger" do
    AssessmentsController.swagger_definitions()
    AssessmentsController.swagger_path_index(nil)
    AssessmentsController.swagger_path_show(nil)
    AssessmentsController.swagger_path_unlock(nil)
    AssessmentsController.swagger_path_submit(nil)
  end

  describe "GET /, unauthenticated" do
    test "unauthorized", %{conn: conn, courses: %{course1: course1}} do
      conn = get(conn, build_url(course1.id))
      assert response(conn, 401) =~ "Unauthorised"
    end
  end

  describe "GET /:assessment_id, unauthenticated" do
    test "unauthorized", %{conn: conn, courses: %{course1: course1}} do
      conn = get(conn, build_url(course1.id, 1))
      assert response(conn, 401) =~ "Unauthorised"
    end
  end

  # All roles should see almost the same overview
  describe "GET /, all roles" do
    test "renders assessments overview", %{
      conn: conn,
      courses: %{course1: course1},
      role_crs: role_crs,
      assessments: assessments
    } do
      for {_role, course_reg} <- role_crs do
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
              "maxTeamSize" => &1.max_team_size,
              "maxXp" => 4800,
              "status" => get_assessment_status(course_reg, &1),
              "private" => false,
              "isPublished" => &1.is_published,
              "gradedCount" => 0,
              "questionCount" => 9,
              "earlySubmissionXp" => &1.config.early_submission_xp,
              "hasVotingFeatures" => &1.has_voting_features,
              "hasTokenCounter" => &1.has_token_counter,
              "isVotingPublished" => false,
              "hoursBeforeEarlyXpDecay" => &1.config.hours_before_early_xp_decay
            }
          )

        resp =
          conn
          |> sign_in(course_reg.user)
          |> get(build_url(course1.id))
          |> json_response(200)
          |> Enum.map(&Map.delete(&1, "xp"))
          |> Enum.map(&Map.delete(&1, "isGradingPublished"))

        assert expected == resp
      end
    end

    test "render password protected assessments properly", %{
      conn: conn,
      courses: %{course1: course1},
      role_crs: role_crs,
      assessment_configs: configs,
      assessments: assessments
    } do
      for {_role, course_reg} <- role_crs do
        mission = assessments[hd(configs).type]

        {:ok, _} =
          mission.assessment
          |> Assessment.changeset(%{password: "mysupersecretpassword"})
          |> Repo.update()

        resp =
          conn
          |> sign_in(course_reg.user)
          |> get(build_url(course1.id))
          |> json_response(200)
          |> Enum.find(&(&1["type"] == hd(configs).type))
          |> Map.get("private")

        assert resp == true
      end
    end
  end

  describe "GET /, student only" do
    test "does not render unpublished assessments", %{
      conn: conn,
      courses: %{course1: course1},
      role_crs: %{student: student},
      assessment_configs: configs,
      assessments: assessments
    } do
      mission = assessments[hd(configs).type]

      {:ok, _} =
        mission.assessment
        |> Assessment.changeset(%{is_published: false})
        |> Repo.update()

      expected =
        assessments
        |> Map.delete(hd(configs).type)
        |> Map.values()
        |> Enum.map(fn a -> a.assessment end)
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
            "maxTeamSize" => &1.max_team_size,
            "maxXp" => 4800,
            "status" => get_assessment_status(student, &1),
            "private" => false,
            "isPublished" => &1.is_published,
            "gradedCount" => 0,
            "questionCount" => 9,
            "isGradingPublished" => false,
            "earlySubmissionXp" => &1.config.early_submission_xp,
            "hasVotingFeatures" => &1.has_voting_features,
            "hasTokenCounter" => &1.has_token_counter,
            "isVotingPublished" => false,
            "hoursBeforeEarlyXpDecay" => &1.config.hours_before_early_xp_decay
          }
        )

      resp =
        conn
        |> sign_in(student.user)
        |> get(build_url(course1.id))
        |> json_response(200)
        |> Enum.map(&Map.delete(&1, "xp"))

      assert expected == resp
    end

    test "renders student submission status in overview", %{
      conn: conn,
      courses: %{course1: course1},
      role_crs: %{student: student},
      assessment_configs: configs,
      assessments: assessments
    } do
      assessment = assessments[hd(configs).type].assessment
      [submission | _] = assessments[hd(configs).type].submissions

      for status <- SubmissionStatus.__enum_map__() do
        submission
        |> Submission.changeset(%{status: status})
        |> Repo.update()

        resp =
          conn
          |> sign_in(student.user)
          |> get(build_url(course1.id))
          |> json_response(200)
          |> Enum.find(&(&1["id"] == assessment.id))
          |> Map.get("status")

        assert get_assessment_status(student, assessment) == resp
      end
    end

    test "renders xp for students", %{
      conn: conn,
      courses: %{course1: course1},
      assessment_configs: configs,
      assessments: assessments,
      student_grading_published: student_grading_published
    } do
      assessment = assessments[hd(configs).type].assessment

      resp =
        conn
        |> sign_in(student_grading_published.user)
        |> get(build_url(course1.id))
        |> json_response(200)
        |> Enum.find(&(&1["id"] == assessment.id))
        |> Map.get("xp")

      assert resp == 800 * 3 + 500 * 3 + 100 * 3
    end
  end

  describe "GET /, non-students" do
    test "renders unpublished assessments", %{
      conn: conn,
      courses: %{course1: course1},
      role_crs: role_crs,
      assessment_configs: configs,
      assessments: assessments
    } do
      for role <- ~w(staff admin)a do
        course_reg = Map.get(role_crs, role)
        mission = assessments[hd(configs).type]

        {:ok, _} =
          mission.assessment
          |> Assessment.changeset(%{is_published: false})
          |> Repo.update()

        resp =
          conn
          |> sign_in(course_reg.user)
          |> get(build_url(course1.id))
          |> json_response(200)
          |> Enum.map(&Map.delete(&1, "xp"))

        expected =
          assessments
          |> Map.values()
          |> Enum.map(fn a -> a.assessment end)
          |> Enum.sort(&open_at_asc_comparator/2)
          |> Enum.map(
            &%{
              "id" => &1.id,
              "courseId" => &1.course_id,
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
              "maxTeamSize" => &1.max_team_size,
              "maxXp" => 4800,
              "status" => get_assessment_status(course_reg, &1),
              "private" => false,
              "gradedCount" => 0,
              "questionCount" => 9,
              "hasVotingFeatures" => &1.has_voting_features,
              "hasTokenCounter" => &1.has_token_counter,
              "isVotingPublished" => false,
              "earlySubmissionXp" => &1.config.early_submission_xp,
              "isGradingPublished" => nil,
              "hoursBeforeEarlyXpDecay" => &1.config.hours_before_early_xp_decay,
              "isPublished" =>
                if &1.config.type == hd(configs).type do
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

  describe "GET /assessment_id, all roles" do
    test "it renders assessment details", %{
      conn: conn,
      courses: %{course1: course1},
      role_crs: role_crs,
      assessments: assessments
    } do
      for role <- Role.__enum_map__() do
        course_reg = Map.get(role_crs, role)

        for {type, %{assessment: assessment}} <- assessments do
          expected_assessments = %{
            "courseId" => assessment.course_id,
            "id" => assessment.id,
            "title" => assessment.title,
            "type" => type,
            "story" => assessment.story,
            "number" => assessment.number,
            "reading" => assessment.reading,
            "longSummary" => assessment.summary_long,
            "hasTokenCounter" => assessment.has_token_counter,
            "missionPDF" => Cadet.Assessments.Upload.url({assessment.mission_pdf, assessment}),
            "isMinigame" => false
          }

          resp_assessments =
            conn
            |> sign_in(course_reg.user)
            |> get(build_url(course1.id, assessment.id))
            |> json_response(200)
            |> Map.delete("questions")

          assert expected_assessments == resp_assessments
        end
      end
    end

    test "it renders assessment questions", %{
      conn: conn,
      courses: %{course1: course1},
      role_crs: role_crs,
      assessments: assessments
    } do
      for role <- Role.__enum_map__() do
        course_reg = Map.get(role_crs, role)

        for {_type,
             %{
               assessment: assessment,
               mcq_questions: mcq_questions,
               programming_questions: programming_questions,
               voting_questions: voting_questions
             }} <- assessments do
          # Programming questions should come first due to seeding order
          expected_programming_questions =
            Enum.map(
              programming_questions,
              &%{
                "id" => &1.id,
                "type" => "#{&1.type}",
                "blocking" => &1.blocking,
                "content" => &1.question.content,
                "solutionTemplate" => &1.question.template,
                "prepend" => &1.question.prepend,
                "postpend" => &1.question.postpend,
                "testcases" =>
                  Enum.map(
                    &1.question.public,
                    fn testcase ->
                      for {k, v} <- testcase,
                          into: %{"type" => "public"},
                          do: {Atom.to_string(k), v}
                    end
                  ) ++
                    Enum.map(
                      &1.question.opaque,
                      fn testcase ->
                        for {k, v} <- testcase,
                            into: %{"type" => "opaque"},
                            do: {Atom.to_string(k), v}
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
                "blocking" => &1.blocking,
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

          expected_voting_questions =
            Enum.map(
              voting_questions,
              &%{
                "id" => &1.id,
                "type" => "#{&1.type}",
                "blocking" => &1.blocking,
                "content" => &1.question.content,
                "solutionTemplate" => &1.question.template,
                "prepend" => &1.question.prepend
              }
            )

          contests_submissions =
            Enum.map(0..2, fn _ -> Enum.map(0..2, fn _ -> insert(:submission) end) end)

          contests_answers =
            Enum.map(contests_submissions, fn contest_submissions ->
              Enum.map(contest_submissions, fn submission ->
                insert(:answer, %{
                  submission: submission,
                  answer: %{code: "return 2;"},
                  question: build(:programming_question)
                })
              end)
            end)

          voting_questions
          |> Enum.zip(contests_submissions)
          |> Enum.map(fn {question, contest_submissions} ->
            Enum.map(contest_submissions, fn submission ->
              insert(:submission_vote, %{
                voter: course_reg,
                submission: submission,
                question: question
              })
            end)
          end)

          contests_entries =
            Enum.map(contests_answers, fn contest_answers ->
              Enum.map(contest_answers, fn answer ->
                %{
                  "submission_id" => answer.submission.id,
                  "answer" => %{"code" => answer.answer.code},
                  "score" => nil
                }
              end)
            end)

          expected_voting_questions =
            expected_voting_questions
            |> Enum.zip(contests_entries)
            |> Enum.map(fn {question, contest_entries} ->
              question
              |> Map.put("contestEntries", contest_entries)
              |> Map.put("scoreLeaderboard", [])
              |> Map.put("popularVoteLeaderboard", [])
            end)

          expected_questions =
            expected_programming_questions ++ expected_mcq_questions ++ expected_voting_questions

          resp_questions =
            conn
            |> sign_in(course_reg.user)
            |> get(build_url(course1.id, assessment.id))
            |> json_response(200)
            |> Map.get("questions", [])
            |> Enum.map(&Map.delete(&1, "answer"))
            |> Enum.map(&Map.delete(&1, "solution"))
            |> Enum.map(&Map.delete(&1, "library"))
            |> Enum.map(&Map.delete(&1, "xp"))
            |> Enum.map(&Map.delete(&1, "lastModifiedAt"))
            |> Enum.map(&Map.delete(&1, "maxXp"))
            |> Enum.map(&Map.delete(&1, "grader"))
            |> Enum.map(&Map.delete(&1, "gradedAt"))
            |> Enum.map(&Map.delete(&1, "autogradingResults"))
            |> Enum.map(&Map.delete(&1, "autogradingStatus"))
            |> Enum.map(&Map.delete(&1, "comments"))

          assert expected_questions == resp_questions
        end
      end
    end

    test "renders open leaderboard for all roles", %{
      conn: conn,
      course_regs: course_regs,
      courses: %{course1: course1},
      role_crs: role_crs,
      assessments: assessments
    } do
      voting_assessment = assessments["practical"].assessment

      voting_assessment
      |> Assessment.changeset(%{
        open_at: Timex.shift(Timex.now(), days: -30),
        close_at: Timex.shift(Timex.now(), days: -20)
      })
      |> Repo.update()

      voting_question = assessments["practical"].voting_questions |> List.first()
      contest_assessment_number = voting_question.question.contest_number

      contest_assessment = Repo.get_by(Assessment, number: contest_assessment_number)

      # insert contest question
      contest_question =
        insert(:programming_question, %{
          display_order: 1,
          assessment: contest_assessment,
          max_xp: 1000
        })

      # insert contest submissions and answers
      contest_submissions =
        for student <- Enum.take(course_regs.students, 5) do
          insert(:submission, %{assessment: contest_assessment, student: student})
        end

      contest_answers =
        for {submission, score} <- Enum.with_index(contest_submissions, 1) do
          insert(:answer, %{
            xp: 1000,
            question: contest_question,
            submission: submission,
            answer: build(:programming_answer),
            relative_score: score / 1
          })
        end

      expected_leaderboard =
        for answer <- contest_answers do
          %{
            "answer" => %{"code" => answer.answer.code},
            "final_score" => answer.relative_score,
            "student_name" => answer.submission.student.user.name,
            "submission_id" => answer.submission.id,
            "student_username" => answer.submission.student.user.username
          }
        end
        |> Enum.sort_by(& &1["final_score"], &>=/2)
        |> Enum.reduce({[], nil, 0, 0}, fn entry, {acc, prev_score, current_rank, index} ->
          new_rank =
            if entry["final_score"] == prev_score do
              current_rank
            else
              index + 1
            end

          updated_entry = Map.put(entry, "rank", new_rank)
          {[updated_entry | acc], entry["final_score"], new_rank, index + 1}
        end)
        |> elem(0)
        |> Enum.reverse()

      for role <- Role.__enum_map__() do
        course_reg = Map.get(role_crs, role)

        resp_leaderboard =
          conn
          |> sign_in(course_reg.user)
          |> get(build_url(course1.id, voting_question.assessment.id))
          |> json_response(200)
          |> Map.get("questions", [])
          |> Enum.find(&(&1["id"] == voting_question.id))
          |> Map.get("scoreLeaderboard")

        assert resp_leaderboard == expected_leaderboard
      end
    end

    test "renders close leaderboard for staff and admin", %{
      conn: conn,
      course_regs: course_regs,
      courses: %{course1: course1},
      role_crs: role_crs,
      assessments: assessments
    } do
      voting_assessment = assessments["practical"].assessment

      voting_assessment
      |> Assessment.changeset(%{
        close_at: Timex.shift(Timex.now(), days: 20)
      })
      |> Repo.update()

      voting_question = assessments["practical"].voting_questions |> List.first()
      contest_assessment_number = voting_question.question.contest_number

      contest_assessment = Repo.get_by(Assessment, number: contest_assessment_number)

      # insert contest question
      contest_question =
        insert(:programming_question, %{
          display_order: 1,
          assessment: contest_assessment,
          max_xp: 1000
        })

      # insert contest submissions and answers
      contest_submissions =
        for student <- Enum.take(course_regs.students, 5) do
          insert(:submission, %{assessment: contest_assessment, student: student})
        end

      contest_answers =
        for {submission, score} <- Enum.with_index(contest_submissions, 1) do
          insert(:answer, %{
            xp: 1000,
            question: contest_question,
            submission: submission,
            answer: build(:programming_answer),
            relative_score: score / 1
          })
        end

      expected_leaderboard =
        for answer <- contest_answers do
          %{
            "answer" => %{"code" => answer.answer.code},
            "final_score" => answer.relative_score,
            "student_name" => answer.submission.student.user.name,
            "submission_id" => answer.submission.id,
            "student_username" => answer.submission.student.user.username
          }
        end
        |> Enum.sort_by(& &1["final_score"], &>=/2)
        |> Enum.reduce({[], nil, 0, 0}, fn entry, {acc, prev_score, current_rank, index} ->
          new_rank =
            if entry["final_score"] == prev_score do
              current_rank
            else
              index + 1
            end

          updated_entry = Map.put(entry, "rank", new_rank)
          {[updated_entry | acc], entry["final_score"], new_rank, index + 1}
        end)
        |> elem(0)
        |> Enum.reverse()

      for role <- [:admin, :staff] do
        course_reg = Map.get(role_crs, role)

        resp_leaderboard =
          conn
          |> sign_in(course_reg.user)
          |> get(build_url(course1.id, voting_question.assessment.id))
          |> json_response(200)
          |> Map.get("questions", [])
          |> Enum.find(&(&1["id"] == voting_question.id))
          |> Map.get("scoreLeaderboard")

        assert resp_leaderboard == expected_leaderboard
      end
    end

    test "does not render close leaderboard for students", %{
      conn: conn,
      course_regs: course_regs,
      courses: %{course1: course1},
      role_crs: %{student: course_reg},
      assessments: assessments
    } do
      voting_assessment = assessments["practical"].assessment

      voting_assessment
      |> Assessment.changeset(%{
        close_at: Timex.shift(Timex.now(), days: 20)
      })
      |> Repo.update()

      voting_question = assessments["practical"].voting_questions |> List.first()
      contest_assessment_number = voting_question.question.contest_number

      contest_assessment = Repo.get_by(Assessment, number: contest_assessment_number)

      # insert contest question
      contest_question =
        insert(:programming_question, %{
          display_order: 1,
          assessment: contest_assessment,
          max_xp: 1000
        })

      # insert contest submissions and answers
      contest_submissions =
        for student <- Enum.take(course_regs.students, 5) do
          insert(:submission, %{assessment: contest_assessment, student: student})
        end

      _contest_answers =
        for {submission, score} <- Enum.with_index(contest_submissions, 1) do
          insert(:answer, %{
            xp: 1000,
            question: contest_question,
            submission: submission,
            answer: build(:programming_answer),
            relative_score: score / 1
          })
        end

      expected_leaderboard = []

      resp_leaderboard =
        conn
        |> sign_in(course_reg.user)
        |> get(build_url(course1.id, voting_question.assessment.id))
        |> json_response(200)
        |> Map.get("questions", [])
        |> Enum.find(&(&1["id"] == voting_question.id))
        |> Map.get("scoreLeaderboard")

      assert resp_leaderboard == expected_leaderboard
    end

    test "it renders assessment question libraries", %{
      conn: conn,
      courses: %{course1: course1},
      role_crs: role_crs,
      assessments: assessments
    } do
      for role <- Role.__enum_map__() do
        course_reg = Map.get(role_crs, role)

        for {_type,
             %{
               assessment: assessment,
               mcq_questions: mcq_questions,
               programming_questions: programming_questions,
               voting_question: voting_questions
             }} <- assessments do
          # Programming questions should come first due to seeding order

          expected_libraries =
            (programming_questions ++ mcq_questions ++ voting_questions)
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
            |> sign_in(course_reg.user)
            |> get(build_url(course1.id, assessment.id))
            |> json_response(200)
            |> Map.get("questions", [])
            |> Enum.map(&Map.get(&1, "library"))

          assert resp_libraries == expected_libraries
        end
      end
    end

    test "it renders solutions for ungraded assessments (path)", %{
      conn: conn,
      courses: %{course1: course1},
      role_crs: role_crs,
      assessments: assessments
    } do
      for role <- Role.__enum_map__() do
        course_reg = Map.get(role_crs, role)

        %{
          assessment: assessment,
          mcq_questions: mcq_questions,
          programming_questions: programming_questions,
          voting_questions: voting_questions
        } = assessments["path"]

        # This is the case cuz the seed set "path" to build_soultion = true

        # Seeds set solution as 0
        expected_mcq_solutions = Enum.map(mcq_questions, fn _ -> %{"solution" => 0} end)

        expected_programming_solutions =
          Enum.map(programming_questions, &%{"solution" => &1.question.solution})

        # No solution in a voting question
        expected_voting_solutions = Enum.map(voting_questions, fn _ -> %{"solution" => nil} end)

        expected_solutions =
          Enum.sort(
            expected_mcq_solutions ++ expected_programming_solutions ++ expected_voting_solutions
          )

        resp_solutions =
          conn
          |> sign_in(course_reg.user)
          |> get(build_url(course1.id, assessment.id))
          |> json_response(200)
          |> Map.get("questions", [])
          |> Enum.map(&Map.take(&1, ["solution"]))
          |> Enum.sort()

        assert expected_solutions == resp_solutions
      end
    end

    test "it renders xp, grade for students", %{
      conn: conn,
      courses: %{course1: course1},
      role_crs: role_crs,
      assessments: assessments,
      student_grading_published: student_grading_published
    } do
      role_crs = Map.put(role_crs, :student, student_grading_published)

      for role <- Role.__enum_map__() do
        course_reg = Map.get(role_crs, role)

        for {_type,
             %{
               assessment: assessment,
               mcq_answers: [mcq_answers | _],
               programming_answers: [programming_answers | _],
               voting_answers: [voting_answers | _]
             }} <- assessments do
          expected =
            if role == :student do
              Enum.map(
                programming_answers ++ mcq_answers ++ voting_answers,
                &%{
                  "xp" => &1.xp + &1.xp_adjustment
                }
              )
            else
              fn -> %{"xp" => 0} end
              |> Stream.repeatedly()
              |> Enum.take(
                length(programming_answers) + length(mcq_answers) + length(voting_answers)
              )
            end

          resp =
            conn
            |> sign_in(course_reg.user)
            |> get(build_url(course1.id, assessment.id))
            |> json_response(200)
            |> Map.get("questions", [])
            |> Enum.map(&Map.take(&1, ~w(xp)))

          assert expected == resp
        end
      end
    end

    test "it does not render solutions for ungraded assessments (path)", %{
      conn: conn,
      courses: %{course1: course1},
      role_crs: role_crs,
      assessments: assessments
    } do
      for role <- Role.__enum_map__() do
        course_reg = Map.get(role_crs, role)

        for {_type,
             %{
               assessment: assessment
             }} <- Map.delete(assessments, "path") do
          resp_solutions =
            conn
            |> sign_in(course_reg.user)
            |> get(build_url(course1.id, assessment.id))
            |> json_response(200)
            |> Map.get("questions", [])
            |> Enum.map(&Map.get(&1, ["solution"]))

          assert Enum.uniq(resp_solutions) == [nil]
        end
      end
    end
  end

  describe "GET /assessment_id, student" do
    test "it renders previously submitted answers", %{
      conn: conn,
      courses: %{course1: course1},
      role_crs: %{student: student},
      assessments: assessments
    } do
      for {_type,
           %{
             assessment: assessment,
             mcq_answers: [mcq_answers | _],
             programming_answers: [programming_answers | _],
             voting_answers: [voting_answers | _]
           }} <- assessments do
        # Programming questions should come first due to seeding order
        expected_programming_answers =
          Enum.map(programming_answers, &%{"answer" => &1.answer.code})

        expected_mcq_answers = Enum.map(mcq_answers, &%{"answer" => &1.answer.choice_id})

        # Answers are not rendered for voting questions
        expected_voting_answers = Enum.map(voting_answers, fn _ -> %{"answer" => nil} end)

        expected_answers =
          expected_programming_answers ++ expected_mcq_answers ++ expected_voting_answers

        resp_answers =
          conn
          |> sign_in(student.user)
          |> get(build_url(course1.id, assessment.id))
          |> json_response(200)
          |> Map.get("questions", [])
          |> Enum.map(&Map.take(&1, ["answer"]))

        assert expected_answers == resp_answers
      end
    end

    test "it does not permit access to not yet open assessments", %{
      conn: conn,
      courses: %{course1: course1},
      role_crs: %{student: student},
      assessments: %{"mission" => mission}
    } do
      mission.assessment
      |> Assessment.changeset(%{
        open_at: Timex.shift(Timex.now(), days: 5),
        close_at: Timex.shift(Timex.now(), days: 10)
      })
      |> Repo.update!()

      conn =
        conn
        |> sign_in(student.user)
        |> get(build_url(course1.id, mission.assessment.id))

      assert response(conn, 403) == "Assessment not open"
    end

    test "it does not permit access to unpublished assessments", %{
      conn: conn,
      courses: %{course1: course1},
      role_crs: %{student: student},
      assessments: %{"mission" => mission}
    } do
      {:ok, _} =
        mission.assessment
        |> Assessment.changeset(%{is_published: false})
        |> Repo.update()

      conn =
        conn
        |> sign_in(student.user)
        |> get(build_url(course1.id, mission.assessment.id))

      assert response(conn, 400) == "Assessment not found"
    end
  end

  describe "GET /assessment_id, non-students" do
    test "it renders empty answers", %{
      conn: conn,
      courses: %{course1: course1},
      role_crs: role_crs,
      assessments: assessments
    } do
      for role <- ~w(staff admin)a do
        course_reg = Map.get(role_crs, role)

        for {_type, %{assessment: assessment}} <- assessments do
          resp_answers =
            conn
            |> sign_in(course_reg.user)
            |> get(build_url(course1.id, assessment.id))
            |> json_response(200)
            |> Map.get("questions", [])
            |> Enum.map(&Map.get(&1, ["answer"]))

          assert Enum.uniq(resp_answers) == [nil]
        end
      end
    end

    test "it permits access to not yet open assessments", %{
      conn: conn,
      courses: %{course1: course1},
      role_crs: role_crs,
      assessments: %{"mission" => mission}
    } do
      for role <- ~w(staff admin)a do
        course_reg = Map.get(role_crs, role)

        mission.assessment
        |> Assessment.changeset(%{
          open_at: Timex.shift(Timex.now(), days: 5),
          close_at: Timex.shift(Timex.now(), days: 10)
        })
        |> Repo.update!()

        resp =
          conn
          |> sign_in(course_reg.user)
          |> get(build_url(course1.id, mission.assessment.id))
          |> json_response(200)

        assert resp["id"] == mission.assessment.id
      end
    end

    test "it permits access to unpublished assessments", %{
      conn: conn,
      courses: %{course1: course1},
      role_crs: role_crs,
      assessments: %{"mission" => mission}
    } do
      for role <- ~w(staff admin)a do
        course_reg = Map.get(role_crs, role)

        {:ok, _} =
          mission.assessment
          |> Assessment.changeset(%{is_published: false})
          |> Repo.update()

        resp =
          conn
          |> sign_in(course_reg.user)
          |> get(build_url(course1.id, mission.assessment.id))
          |> json_response(200)

        assert resp["id"] == mission.assessment.id
      end
    end
  end

  describe "GET /assessment_id/submit unauthenticated" do
    test "is not permitted", %{
      conn: conn,
      courses: %{course1: course1},
      assessments: %{"mission" => %{assessment: assessment}}
    } do
      conn = post(conn, build_url_submit(course1.id, assessment.id))
      assert response(conn, 401) == "Unauthorised"
    end
  end

  describe "GET /assessment_id/submit students" do
    for role <- ~w(student staff admin)a do
      @tag role: role
      test "is successful for attempted assessments for #{role}", %{
        conn: conn,
        courses: %{course1: course1},
        assessments: %{"mission" => %{assessment: assessment}},
        role_crs: role_crs,
        role: role
      } do
        with_mock GradingJob,
          force_grade_individual_submission: fn _ -> nil end do
          group =
            if(role == :student,
              do: insert(:group, %{course: course1, leader: role_crs.staff}),
              else: nil
            )

          course_reg = insert(:course_registration, %{role: role, group: group, course: course1})

          submission =
            insert(:submission, %{student: course_reg, assessment: assessment, status: :attempted})

          conn =
            conn
            |> sign_in(course_reg.user)
            |> post(build_url_submit(course1.id, assessment.id))

          assert response(conn, 200) == "OK"

          # Preloading is necessary because Mock does an exact match, including metadata
          submission_db = Submission |> Repo.get(submission.id) |> Repo.preload(:assessment)

          assert submission_db.status == :submitted

          assert_called(GradingJob.force_grade_individual_submission(submission_db))
        end
      end
    end

    test "submission of answer with no effort grants 0 XP bonus", %{
      conn: conn,
      courses: %{course1: course1},
      role_crs: role_crs
    } do
      with_mock GradingJob, force_grade_individual_submission: fn _ -> nil end do
        assessment_config =
          insert(
            :assessment_config,
            early_submission_xp: 100,
            hours_before_early_xp_decay: 48,
            course: course1
          )

        assessment =
          insert(
            :assessment,
            open_at: Timex.shift(Timex.now(), hours: -40),
            close_at: Timex.shift(Timex.now(), days: 7),
            is_published: true,
            config: assessment_config,
            course: course1
          )

        question = insert(:programming_question, assessment: assessment)

        group = insert(:group, leader: role_crs.staff)

        course_reg =
          insert(:course_registration, %{role: :student, group: group, course: course1})

        submission =
          insert(:submission, assessment: assessment, student: course_reg, status: :attempted)

        insert(
          :answer,
          submission: submission,
          question: question,
          answer: %{code: "f => f(f);"}
        )

        conn
        |> sign_in(course_reg.user)
        |> post(build_url_submit(course1.id, assessment.id))
        |> response(200)

        submission_db = Repo.get(Submission, submission.id)

        assert submission_db.status == :submitted
        assert submission_db.xp_bonus == 0
      end
    end

    test "submission of answer grants XP bonus only after being marked by an avenger", %{
      conn: conn,
      courses: %{course1: course1},
      role_crs: role_crs
    } do
      with_mock GradingJob, force_grade_individual_submission: fn _ -> nil end do
        assessment_config =
          insert(
            :assessment_config,
            early_submission_xp: 100,
            hours_before_early_xp_decay: 48,
            course: course1
          )

        assessment =
          insert(
            :assessment,
            open_at: Timex.shift(Timex.now(), hours: -40),
            close_at: Timex.shift(Timex.now(), days: 7),
            is_published: true,
            config: assessment_config,
            course: course1
          )

        question = insert(:programming_question, assessment: assessment)

        group = insert(:group, leader: role_crs.staff)

        course_reg =
          insert(:course_registration, %{role: :student, group: group, course: course1})

        submission =
          insert(:submission, assessment: assessment, student: course_reg, status: :attempted)

        insert(
          :answer,
          submission: submission,
          question: question,
          answer: %{code: "f => f(f);"},
          xp_adjustment: 0
        )

        conn
        |> sign_in(course_reg.user)
        |> post(build_url_submit(course1.id, assessment.id))
        |> response(200)

        submission_db = Repo.get(Submission, submission.id)

        assert submission_db.status == :submitted
        assert submission_db.xp_bonus == 0

        grade_question = fn question ->
          Assessments.update_grading_info(
            %{submission_id: submission.id, question_id: question.id},
            %{"xp_adjustment" => 10},
            role_crs.staff
          )
        end

        grade_question.(question)

        submission_db = Repo.get(Submission, submission.id)
        assert submission_db.xp_bonus == 100
      end
    end

    test "submission of answer grants 0 XP bonus if an avenger gives 0 as well", %{
      conn: conn,
      courses: %{course1: course1},
      role_crs: role_crs
    } do
      with_mock GradingJob, force_grade_individual_submission: fn _ -> nil end do
        assessment_config =
          insert(
            :assessment_config,
            early_submission_xp: 100,
            hours_before_early_xp_decay: 48,
            course: course1
          )

        assessment =
          insert(
            :assessment,
            open_at: Timex.shift(Timex.now(), hours: -40),
            close_at: Timex.shift(Timex.now(), days: 7),
            is_published: true,
            config: assessment_config,
            course: course1
          )

        question = insert(:programming_question, assessment: assessment)

        group = insert(:group, leader: role_crs.staff)

        course_reg =
          insert(:course_registration, %{role: :student, group: group, course: course1})

        submission =
          insert(:submission, assessment: assessment, student: course_reg, status: :attempted)

        insert(
          :answer,
          submission: submission,
          question: question,
          answer: %{code: "f => f(f);"},
          xp_adjustment: 0
        )

        conn
        |> sign_in(course_reg.user)
        |> post(build_url_submit(course1.id, assessment.id))
        |> response(200)

        submission_db = Repo.get(Submission, submission.id)

        assert submission_db.status == :submitted
        assert submission_db.xp_bonus == 0

        grade_question = fn question ->
          Assessments.update_grading_info(
            %{submission_id: submission.id, question_id: question.id},
            %{"xp_adjustment" => 0},
            role_crs.staff
          )
        end

        grade_question.(question)

        submission_db = Repo.get(Submission, submission.id)
        assert submission_db.xp_bonus == 0
      end
    end

    test "submission of answer within early hours(seeded 48) of opening grants full XP bonus", %{
      conn: conn,
      courses: %{course1: course1},
      role_crs: role_crs
    } do
      with_mock GradingJob, force_grade_individual_submission: fn _ -> nil end do
        assessment_config =
          insert(
            :assessment_config,
            early_submission_xp: 100,
            hours_before_early_xp_decay: 48,
            course: course1
          )

        assessment =
          insert(
            :assessment,
            open_at: Timex.shift(Timex.now(), hours: -40),
            close_at: Timex.shift(Timex.now(), days: 7),
            is_published: true,
            config: assessment_config,
            course: course1
          )

        question = insert(:programming_question, assessment: assessment)

        group = insert(:group, leader: role_crs.staff)

        course_reg =
          insert(:course_registration, %{role: :student, group: group, course: course1})

        submission =
          insert(:submission, assessment: assessment, student: course_reg, status: :attempted)

        insert(
          :answer,
          submission: submission,
          question: question,
          answer: %{code: "f => f(f);"},
          xp: 10
        )

        conn
        |> sign_in(course_reg.user)
        |> post(build_url_submit(course1.id, assessment.id))
        |> response(200)

        submission_db = Repo.get(Submission, submission.id)

        assert submission_db.status == :submitted
        assert submission_db.xp_bonus == 100
      end
    end

    test "submission of answer after early hours before deadline get decaying XP bonus", %{
      conn: conn,
      courses: %{course1: course1},
      role_crs: role_crs
    } do
      with_mock GradingJob, force_grade_individual_submission: fn _ -> nil end do
        for hours_after <- 48..148 do
          assessment_config =
            insert(
              :assessment_config,
              early_submission_xp: 100,
              hours_before_early_xp_decay: 48,
              course: course1
            )

          assessment =
            insert(
              :assessment,
              open_at: Timex.shift(Timex.now(), hours: -hours_after),
              close_at: Timex.shift(Timex.now(), hours: 100),
              is_published: true,
              config: assessment_config,
              course: course1
            )

          question = insert(:programming_question, assessment: assessment)

          group = insert(:group, leader: role_crs.staff)

          course_reg =
            insert(:course_registration, %{role: :student, group: group, course: course1})

          submission =
            insert(:submission, assessment: assessment, student: course_reg, status: :attempted)

          insert(
            :answer,
            submission: submission,
            question: question,
            answer: %{code: "f => f(f);"},
            xp: 10
          )

          conn
          |> sign_in(course_reg.user)
          |> post(build_url_submit(course1.id, assessment.id))
          |> response(200)

          submission_db = Repo.get(Submission, submission.id)

          proportion =
            Timex.diff(assessment.close_at, Timex.now(), :hours) / (100 + hours_after - 48)

          assert submission_db.status == :submitted
          assert submission_db.xp_bonus == round(proportion * 100)
        end
      end
    end

    test "submission of answer at the last hour yield 0 XP bonus", %{
      conn: conn,
      courses: %{course1: course1},
      role_crs: role_crs
    } do
      with_mock GradingJob, force_grade_individual_submission: fn _ -> nil end do
        for hours_after <- 48..148 do
          assessment_config =
            insert(
              :assessment_config,
              early_submission_xp: 100,
              hours_before_early_xp_decay: 48,
              course: course1
            )

          assessment =
            insert(
              :assessment,
              open_at: Timex.shift(Timex.now(), hours: -hours_after),
              close_at: Timex.shift(Timex.now(), hours: 1),
              is_published: true,
              config: assessment_config,
              course: course1
            )

          question = insert(:programming_question, assessment: assessment)

          group = insert(:group, leader: role_crs.staff)

          course_reg =
            insert(:course_registration, %{role: :student, group: group, course: course1})

          submission =
            insert(:submission, assessment: assessment, student: course_reg, status: :attempted)

          insert(
            :answer,
            submission: submission,
            question: question,
            answer: %{code: "f => f(f);"},
            xp: 10
          )

          conn
          |> sign_in(course_reg.user)
          |> post(build_url_submit(course1.id, assessment.id))
          |> response(200)

          submission_db = Repo.get(Submission, submission.id)

          assert submission_db.status == :submitted
          assert submission_db.xp_bonus == 0
        end
      end
    end

    test "give 0 bonus for configs with 0 max", %{
      conn: conn,
      courses: %{course1: course1},
      role_crs: role_crs
    } do
      with_mock GradingJob, force_grade_individual_submission: fn _ -> nil end do
        for hours_after <- 0..148 do
          assessment_config =
            insert(
              :assessment_config,
              early_submission_xp: 0,
              hours_before_early_xp_decay: 48,
              course: course1
            )

          assessment =
            insert(
              :assessment,
              open_at: Timex.shift(Timex.now(), hours: -hours_after),
              close_at: Timex.shift(Timex.now(), days: 7),
              is_published: true,
              config: assessment_config,
              course: course1
            )

          question = insert(:programming_question, assessment: assessment)

          group = insert(:group, leader: role_crs.staff)

          course_reg =
            insert(:course_registration, %{role: :student, group: group, course: course1})

          submission =
            insert(:submission, assessment: assessment, student: course_reg, status: :attempted)

          insert(
            :answer,
            submission: submission,
            question: question,
            answer: %{code: "f => f(f);"}
          )

          conn
          |> sign_in(course_reg.user)
          |> post(build_url_submit(course1.id, assessment.id))
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
      courses: %{course1: course1},
      assessments: %{"mission" => %{assessment: assessment}}
    } do
      course_reg = insert(:course_registration, %{role: :student, course: course1})

      conn =
        conn
        |> sign_in(course_reg.user)
        |> post(build_url_submit(course1.id, assessment.id))

      assert response(conn, 404) == "Submission not found"
    end

    test "is not permitted for incomplete assessments", %{
      conn: conn,
      courses: %{course1: course1},
      assessments: %{"mission" => %{assessment: assessment}}
    } do
      course_reg = insert(:course_registration, %{role: :student, course: course1})
      insert(:submission, %{student: course_reg, assessment: assessment, status: :attempting})

      conn =
        conn
        |> sign_in(course_reg.user)
        |> post(build_url_submit(course1.id, assessment.id))

      assert response(conn, 400) == "Some questions have not been attempted"
    end

    test "is not permitted for already submitted assessments", %{
      conn: conn,
      courses: %{course1: course1},
      assessments: %{"mission" => %{assessment: assessment}}
    } do
      course_reg = insert(:course_registration, %{role: :student, course: course1})
      insert(:submission, %{student: course_reg, assessment: assessment, status: :submitted})

      conn =
        conn
        |> sign_in(course_reg.user)
        |> post(build_url_submit(course1.id, assessment.id))

      assert response(conn, 403) == "Assessment has already been submitted"
    end

    test "is not permitted for closed assessments", %{conn: conn, courses: %{course1: course1}} do
      course_reg = insert(:course_registration, %{role: :student, course: course1})

      # Only check for after-closing because submission shouldn't exist if unpublished or
      # before opening and would fall under "Submission not found"
      after_close_at_assessment =
        insert(:assessment, %{
          open_at: Timex.shift(Timex.now(), days: -10),
          close_at: Timex.shift(Timex.now(), days: -5),
          course: course1
        })

      insert(:submission, %{
        student: course_reg,
        assessment: after_close_at_assessment,
        status: :attempted
      })

      conn =
        conn
        |> sign_in(course_reg.user)
        |> post(build_url_submit(course1.id, after_close_at_assessment.id))

      assert response(conn, 403) == "Assessment not open"
    end

    test "not found if not in same course", %{
      conn: conn,
      courses: %{course2: course2},
      role_crs: %{student: student},
      assessments: %{"mission" => %{assessment: assessment}}
    } do
      # user is in both course, but assessment belongs to a course and no submission will be found
      conn =
        conn
        |> sign_in(student.user)
        |> post(build_url_submit(course2.id, assessment.id))

      assert response(conn, 404) == "Submission not found"
    end

    test "forbidden if not in course", %{
      conn: conn,
      courses: %{course2: course2},
      course_regs: %{students: students},
      assessments: %{"mission" => %{assessment: assessment}}
    } do
      # user is not in the course
      student2 = hd(tl(students))

      conn =
        conn
        |> sign_in(student2.user)
        |> post(build_url_submit(course2.id, assessment.id))

      assert response(conn, 403) == "Forbidden"
    end
  end

  test "graded count is updated when assessment is graded", %{
    conn: conn,
    courses: %{course1: course1},
    assessment_configs: [config | _],
    role_crs: %{staff: avenger}
  } do
    assessment =
      insert(
        :assessment,
        open_at: Timex.shift(Timex.now(), hours: -2),
        close_at: Timex.shift(Timex.now(), days: 7),
        is_published: true,
        config: config,
        course: course1
      )

    [question_one, question_two] = insert_list(2, :programming_question, assessment: assessment)

    course_reg = insert(:course_registration, role: :student, course: course1)

    submission =
      insert(:submission,
        assessment: assessment,
        student: course_reg,
        status: :submitted,
        is_grading_published: true
      )

    Enum.each(
      [question_one, question_two],
      &insert(:answer, submission: submission, question: &1, answer: %{code: "f => f(f);"})
    )

    get_graded_count = fn ->
      conn
      |> sign_in(course_reg.user)
      |> get(build_url(course1.id))
      |> json_response(200)
      |> Enum.find(&(&1["id"] == assessment.id))
      |> Map.get("gradedCount")
    end

    grade_question = fn question ->
      Assessments.update_grading_info(
        %{submission_id: submission.id, question_id: question.id},
        %{"xp_adjustment" => 0},
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
    setup %{courses: %{course1: course1}, assessment_configs: configs} do
      assessment =
        insert(:assessment, %{config: Enum.at(configs, 4), course: course1, is_published: true})

      assessment
      |> Assessment.changeset(%{
        password: "mysupersecretpassword",
        open_at: Timex.shift(Timex.now(), days: -2),
        close_at: Timex.shift(Timex.now(), days: +1)
      })
      |> Repo.update!()

      {:ok, protected_assessment: assessment}
    end

    test "returns 403 when trying to access a password protected assessment without a password",
         %{
           conn: conn,
           courses: %{course1: course1},
           protected_assessment: protected_assessment,
           role_crs: role_crs
         } do
      for {_role, course_reg} <- role_crs do
        conn =
          conn |> sign_in(course_reg.user) |> get(build_url(course1.id, protected_assessment.id))

        assert response(conn, 403) == "Missing Password."
      end
    end

    test "returns 403 when password is wrong/invalid", %{
      conn: conn,
      courses: %{course1: course1},
      protected_assessment: protected_assessment,
      role_crs: role_crs
    } do
      for {_role, course_reg} <- role_crs do
        conn =
          conn
          |> sign_in(course_reg.user)
          |> post(build_url_unlock(course1.id, protected_assessment.id), %{:password => "wrong"})

        assert response(conn, 403) == "Invalid Password."
      end
    end

    test "allow role_crs with preexisting submission to access private assessment without a password",
         %{
           conn: conn,
           courses: %{course1: course1},
           protected_assessment: protected_assessment,
           role_crs: %{student: student}
         } do
      insert(:submission, %{assessment: protected_assessment, student: student})
      conn = conn |> sign_in(student.user) |> get(build_url(course1.id, protected_assessment.id))
      assert response(conn, 200)
    end

    test "ignore password when assessment is not password protected", %{
      conn: conn,
      courses: %{course1: course1},
      role_crs: role_crs,
      assessments: assessments
    } do
      assessment = assessments["mission"].assessment

      for {_role, course_reg} <- role_crs do
        conn =
          conn
          |> sign_in(course_reg.user)
          |> post(build_url_unlock(course1.id, assessment.id), %{:password => "wrong"})
          |> json_response(200)

        assert conn["id"] == assessment.id
      end
    end

    test "render assessment when password is correct", %{
      conn: conn,
      courses: %{course1: course1},
      protected_assessment: protected_assessment,
      role_crs: role_crs
    } do
      for {_role, course_reg} <- role_crs do
        conn =
          conn
          |> sign_in(course_reg.user)
          |> post(build_url_unlock(course1.id, protected_assessment.id), %{
            :password => "mysupersecretpassword"
          })
          |> json_response(200)

        assert conn["id"] == protected_assessment.id
      end
    end

    test "permit global access to private assessment after closed", %{
      conn: conn,
      courses: %{course1: course1},
      role_crs: %{student: student},
      assessments: %{"mission" => mission}
    } do
      mission.assessment
      |> Assessment.changeset(%{
        open_at: Timex.shift(Timex.now(), days: -2),
        close_at: Timex.shift(Timex.now(), days: -1)
      })
      |> Repo.update!()

      conn =
        conn
        |> sign_in(student.user)
        |> get(build_url(course1.id, mission.assessment.id))

      assert response(conn, 200)
    end
  end

  describe "GET /:assessment_id/contest_popular_leaderboard, unauthenticated" do
    test "unauthorized", %{conn: conn, courses: %{course1: course1}} do
      config = insert(:assessment_config, %{course: course1})
      assessment = insert(:assessment, %{course: course1, config: config})

      params = %{
        "count" => 9
      }

      conn
      |> get(build_popular_leaderboard_url(course1.id, assessment.id, params))
      |> response(401)
    end
  end

  describe "GET /:assessment_id/contest_score_leaderboard, unauthenticated" do
    test "unauthorized", %{conn: conn, courses: %{course1: course1}} do
      config = insert(:assessment_config, %{course: course1})
      assessment = insert(:assessment, %{course: course1, config: config})

      params = %{
        "count" => 9
      }

      conn
      |> get(build_score_leaderboard_url(course1.id, assessment.id, params))
      |> response(401)
    end
  end

  describe "GET /:assessment_id/contest_popular_leaderboard" do
    @tag authenticate: :student
    test "successful", %{conn: conn, courses: %{course1: course1}} do
      user = conn.assigns[:current_user]
      test_cr = insert(:course_registration, %{course: course1, role: :student, user: user})
      conn = assign(conn, :test_cr, test_cr)
      course = test_cr.course

      config = insert(:assessment_config, %{course: course})
      contest_assessment = insert(:assessment, %{course: course, config: config})
      contest_students = insert_list(5, :course_registration, %{course: course, role: :student})
      contest_question = insert(:programming_question, %{assessment: contest_assessment})

      contest_submissions =
        contest_students
        |> Enum.map(&insert(:submission, %{assessment: contest_assessment, student: &1}))

      contest_answer =
        contest_submissions
        |> Enum.map(
          &insert(:answer, %{
            question: contest_question,
            submission: &1,
            popular_score: 10.0,
            answer: build(:programming_answer)
          })
        )

      voting_assessment = insert(:assessment, %{course: course, config: config})

      insert(
        :voting_question,
        %{
          question: build(:voting_question_content, contest_number: contest_assessment.number),
          assessment: voting_assessment
        }
      )

      expected =
        contest_answer
        |> Enum.map(
          &%{
            "answer" => &1.answer.code,
            "student_name" => &1.submission.student.user.name,
            "final_score" => &1.popular_score,
            "rank" => 1,
            "student_username" => &1.submission.student.user.username,
            "submission_id" => &1.submission.id
          }
        )

      params = %{
        "count" => 1
      }

      resp =
        conn
        |> get(build_popular_leaderboard_url(course.id, voting_assessment.id, params))
        |> json_response(200)

      assert expected == resp["leaderboard"]
    end
  end

  describe "GET /:assessment_id/contest_score_leaderboard" do
    @tag authenticate: :student
    test "successful", %{conn: conn, courses: %{course1: course1}} do
      user = conn.assigns[:current_user]
      test_cr = insert(:course_registration, %{course: course1, role: :student, user: user})
      conn = assign(conn, :test_cr, test_cr)
      course = test_cr.course

      config = insert(:assessment_config, %{course: course})
      contest_assessment = insert(:assessment, %{course: course, config: config})
      contest_students = insert_list(5, :course_registration, %{course: course, role: :student})
      contest_question = insert(:programming_question, %{assessment: contest_assessment})

      contest_submissions =
        contest_students
        |> Enum.map(&insert(:submission, %{assessment: contest_assessment, student: &1}))

      contest_answer =
        contest_submissions
        |> Enum.map(
          &insert(:answer, %{
            question: contest_question,
            submission: &1,
            relative_score: 10.0,
            answer: build(:programming_answer)
          })
        )

      voting_assessment = insert(:assessment, %{course: course, config: config})

      insert(
        :voting_question,
        %{
          question: build(:voting_question_content, contest_number: contest_assessment.number),
          assessment: voting_assessment
        }
      )

      expected =
        contest_answer
        |> Enum.map(
          &%{
            "answer" => &1.answer.code,
            "student_name" => &1.submission.student.user.name,
            "final_score" => &1.relative_score,
            "rank" => 1,
            "student_username" => &1.submission.student.user.username,
            "submission_id" => &1.submission.id
          }
        )

      params = %{
        "count" => 1
      }

      resp =
        conn
        |> get(build_score_leaderboard_url(course.id, voting_assessment.id, params))
        |> json_response(200)

      assert expected == resp["leaderboard"]
    end
  end

  defp build_url(course_id), do: "/v2/courses/#{course_id}/assessments/"

  defp build_url(course_id, assessment_id),
    do: "/v2/courses/#{course_id}/assessments/#{assessment_id}"

  defp build_url_submit(course_id, assessment_id),
    do: "/v2/courses/#{course_id}/assessments/#{assessment_id}/submit"

  defp build_url_unlock(course_id, assessment_id),
    do: "/v2/courses/#{course_id}/assessments/#{assessment_id}/unlock"

  defp build_popular_leaderboard_url(course_id, assessment_id, params \\ %{}) do
    base_url = "#{build_url(course_id, assessment_id)}/contest_popular_leaderboard"

    if params != %{} do
      query_string = URI.encode_query(params)
      "#{base_url}?#{query_string}"
    else
      base_url
    end
  end

  defp build_score_leaderboard_url(course_id, assessment_id, params \\ %{}) do
    base_url = "#{build_url(course_id, assessment_id)}/contest_score_leaderboard"

    if params != %{} do
      query_string = URI.encode_query(params)
      "#{base_url}?#{query_string}"
    else
      base_url
    end
  end

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
