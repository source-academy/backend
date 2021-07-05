defmodule CadetWeb.AdminGradingControllerTest do
  use CadetWeb.ConnCase

  alias Cadet.Assessments.{Answer, Submission}
  alias Cadet.Repo
  alias CadetWeb.AdminGradingController

  import Mock

  test "swagger" do
    AdminGradingController.swagger_definitions()
    AdminGradingController.swagger_path_index(nil)
    AdminGradingController.swagger_path_show(nil)
    AdminGradingController.swagger_path_update(nil)
    AdminGradingController.swagger_path_unsubmit(nil)
    AdminGradingController.swagger_path_autograde_submission(nil)
    AdminGradingController.swagger_path_autograde_answer(nil)
    AdminGradingController.swagger_path_grading_summary(nil)
  end

  describe "GET /, unauthenticated" do
    test "unauthorized", %{conn: conn} do
      course = insert(:course)
      conn = get(conn, build_url(course.id))
      assert response(conn, 401) =~ "Unauthorised"
    end
  end

  describe "GET /:submissionid, unauthenticated" do
    test "unauthorized", %{conn: conn} do
      course = insert(:course)
      conn = get(conn, build_url(course.id, 1))
      assert response(conn, 401) =~ "Unauthorised"
    end
  end

  describe "POST /:submissionid/:questionid, unauthenticated" do
    test "unauthorized", %{conn: conn} do
      course = insert(:course)
      conn = post(conn, build_url(course.id, 1, 3), %{})
      assert response(conn, 401) =~ "Unauthorised"
    end
  end

  describe "GET /:submissionid/unsubmit, unauthenticated" do
    test "unauthorized", %{conn: conn} do
      course = insert(:course)
      conn = post(conn, build_url_unsubmit(course.id, 1))
      assert response(conn, 401) =~ "Unauthorised"
    end
  end

  describe "GET /, student" do
    @tag authenticate: :student
    test "Forbidden", %{conn: conn} do
      course_id = conn.assigns.course_id
      conn = get(conn, build_url(course_id))
      assert response(conn, 403) =~ "Forbidden"
    end
  end

  describe "GET /?group=true, student" do
    @tag authenticate: :student
    test "Forbidden", %{conn: conn} do
      course_id = conn.assigns.course_id
      conn = get(conn, build_url(course_id), %{"group" => "true"})
      assert response(conn, 403) =~ "Forbidden"
    end
  end

  describe "GET /:submissionid, student" do
    @tag authenticate: :student
    test "Forbidden", %{conn: conn} do
      course_id = conn.assigns.course_id
      conn = get(conn, build_url(course_id, 1))
      assert response(conn, 403) =~ "Forbidden"
    end
  end

  describe "POST /:submissionid/:questionid, student" do
    @tag authenticate: :student
    test "Forbidden", %{conn: conn} do
      course_id = conn.assigns.course_id
      conn = post(conn, build_url(course_id, 1, 3), %{"grading" => %{}})
      assert response(conn, 403) =~ "Forbidden"
    end

    @tag authenticate: :student
    test "missing parameter", %{conn: conn} do
      course_id = conn.assigns.course_id
      conn = post(conn, build_url(course_id, 1, 3), %{})
      assert response(conn, 403) =~ "Forbidden"
    end
  end

  describe "GET /:submissionid/unsubmit, student" do
    @tag authenticate: :student
    test "Forbidden", %{conn: conn} do
      course_id = conn.assigns.course_id
      conn = post(conn, build_url_unsubmit(course_id, 1))
      assert response(conn, 403) =~ "Forbidden"
    end
  end

  describe "GET /, staff" do
    @tag authenticate: :staff
    test "avenger gets to see all students submissions", %{conn: conn} do
      %{
        course: course,
        mission: mission,
        submissions: submissions
      } = seed_db(conn)

      conn = get(conn, build_url(course.id))

      expected =
        Enum.map(submissions, fn submission ->
          %{
            "xp" => 5000,
            "xpAdjustment" => -2500,
            "xpBonus" => 100,
            "id" => submission.id,
            "student" => %{
              "name" => submission.student.user.name,
              "id" => submission.student.id,
              "groupName" => submission.student.group.name,
              "groupLeaderId" => submission.student.group.leader_id
            },
            "assessment" => %{
              "type" => mission.config.type,
              "isManuallyGraded" => mission.config.is_manually_graded,
              "maxXp" => 5000,
              "id" => mission.id,
              "title" => mission.title,
              "questionCount" => 5
            },
            "status" => Atom.to_string(submission.status),
            "gradedCount" => 5,
            "unsubmittedBy" => nil,
            "unsubmittedAt" => nil
          }
        end)

      assert expected == Enum.sort_by(json_response(conn, 200), & &1["id"])
    end
  end

  describe "GET /?group=true, staff" do
    @tag authenticate: :staff
    test "staff not leading a group to get empty", %{conn: conn} do
      seed_db(conn)

      test_cr = conn.assigns.test_cr
      new_staff = insert(:course_registration, %{course: test_cr.course, role: :staff})

      resp =
        conn
        |> sign_in(new_staff.user)
        |> get(build_url(test_cr.course_id), %{"group" => "true"})
        |> json_response(200)

      assert resp == []
    end

    @tag authenticate: :staff
    test "filtered by its own group", %{conn: conn} do
      %{
        course: course,
        mission: mission,
        submissions: submissions
      } = seed_db(conn)

      # just to insert more submissions
      new_staff = insert(:course_registration, %{course: course, role: :staff})
      seed_db(conn, new_staff)

      conn = get(conn, build_url(course.id), %{"group" => "true"})

      expected =
        Enum.map(submissions, fn submission ->
          %{
            "xp" => 5000,
            "xpAdjustment" => -2500,
            "xpBonus" => 100,
            "id" => submission.id,
            "student" => %{
              "name" => submission.student.user.name,
              "id" => submission.student.id,
              "groupName" => submission.student.group.name,
              "groupLeaderId" => submission.student.group.leader_id
            },
            "assessment" => %{
              "type" => mission.config.type,
              "isManuallyGraded" => mission.config.is_manually_graded,
              "maxXp" => 5000,
              "id" => mission.id,
              "title" => mission.title,
              "questionCount" => 5
            },
            "status" => Atom.to_string(submission.status),
            "gradedCount" => 5,
            "unsubmittedBy" => nil,
            "unsubmittedAt" => nil
          }
        end)

      assert expected == Enum.sort_by(json_response(conn, 200), & &1["id"])
    end
  end

  describe "GET /:submissionid, staff" do
    @tag authenticate: :staff
    test "successful", %{conn: conn} do
      %{
        course: course,
        grader: grader,
        submissions: submissions,
        answers: answers
      } = seed_db(conn)

      submission = List.first(submissions)

      conn = get(conn, build_url(course.id, submission.id))

      expected =
        answers
        |> Enum.filter(&(&1.submission.id == submission.id))
        |> Enum.sort_by(& &1.question.display_order)
        |> Enum.map(
          &case &1.question.type do
            :programming ->
              %{
                "question" => %{
                  "prepend" => &1.question.question.prepend,
                  "postpend" => &1.question.question.postpend,
                  "testcases" =>
                    Enum.map(
                      &1.question.question.public,
                      fn testcase ->
                        for {k, v} <- testcase,
                            into: %{"type" => "public"},
                            do: {Atom.to_string(k), v}
                      end
                    ) ++
                      Enum.map(
                        &1.question.question.private,
                        fn testcase ->
                          for {k, v} <- testcase,
                              into: %{"type" => "private"},
                              do: {Atom.to_string(k), v}
                        end
                      ),
                  "solutionTemplate" => &1.question.question.template,
                  "type" => "#{&1.question.type}",
                  "blocking" => &1.question.blocking,
                  "id" => &1.question.id,
                  "library" => %{
                    "chapter" => &1.question.library.chapter,
                    "globals" => &1.question.library.globals,
                    "external" => %{
                      "name" => "#{&1.question.library.external.name}",
                      "symbols" => &1.question.library.external.symbols
                    }
                  },
                  "maxXp" => &1.question.max_xp,
                  "content" => &1.question.question.content,
                  "answer" => &1.answer.code,
                  "autogradingStatus" => Atom.to_string(&1.autograding_status),
                  "autogradingResults" => &1.autograding_results
                },
                "solution" => &1.question.question.solution,
                "grade" => %{
                  "xp" => &1.xp,
                  "xpAdjustment" => &1.xp_adjustment,
                  "grader" => %{
                    "name" => grader.user.name,
                    "id" => grader.id
                  },
                  "gradedAt" => format_datetime(&1.updated_at),
                  "comments" => &1.comments
                },
                "student" => %{
                  "name" => &1.submission.student.user.name,
                  "id" => &1.submission.student.id
                }
              }

            :mcq ->
              %{
                "question" => %{
                  "type" => "#{&1.question.type}",
                  "blocking" => &1.question.blocking,
                  "id" => &1.question.id,
                  "library" => %{
                    "chapter" => &1.question.library.chapter,
                    "globals" => &1.question.library.globals,
                    "external" => %{
                      "name" => "#{&1.question.library.external.name}",
                      "symbols" => &1.question.library.external.symbols
                    }
                  },
                  "maxXp" => &1.question.max_xp,
                  "content" => &1.question.question.content,
                  "answer" => &1.answer.choice_id,
                  "choices" =>
                    for choice <- &1.question.question.choices do
                      %{
                        "content" => choice.content,
                        "hint" => choice.hint,
                        "id" => choice.choice_id
                      }
                    end,
                  "autogradingStatus" => Atom.to_string(&1.autograding_status),
                  "autogradingResults" => &1.autograding_results
                },
                "solution" => "",
                "grade" => %{
                  "xp" => &1.xp,
                  "xpAdjustment" => &1.xp_adjustment,
                  "grader" => %{
                    "name" => grader.user.name,
                    "id" => grader.id
                  },
                  "gradedAt" => format_datetime(&1.updated_at),
                  "comments" => &1.comments
                },
                "student" => %{
                  "name" => &1.submission.student.user.name,
                  "id" => &1.submission.student.id
                }
              }

            :voting ->
              %{
                "question" => %{
                  "prepend" => &1.question.question.prepend,
                  "solutionTemplate" => &1.question.question.template,
                  "type" => "#{&1.question.type}",
                  "blocking" => &1.question.blocking,
                  "id" => &1.question.id,
                  "library" => %{
                    "chapter" => &1.question.library.chapter,
                    "globals" => &1.question.library.globals,
                    "external" => %{
                      "name" => "#{&1.question.library.external.name}",
                      "symbols" => &1.question.library.external.symbols
                    }
                  },
                  "maxXp" => &1.question.max_xp,
                  "content" => &1.question.question.content,
                  "autogradingStatus" => Atom.to_string(&1.autograding_status),
                  "autogradingResults" => &1.autograding_results,
                  "answer" => nil,
                  "contestEntries" => [],
                  "contestLeaderboard" => []
                },
                "grade" => %{
                  "xp" => &1.xp,
                  "xpAdjustment" => &1.xp_adjustment,
                  "grader" => %{
                    "name" => grader.user.name,
                    "id" => grader.id
                  },
                  "gradedAt" => format_datetime(&1.updated_at),
                  "comments" => &1.comments
                },
                "student" => %{
                  "name" => &1.submission.student.user.name,
                  "id" => &1.submission.student.id
                },
                "solution" => ""
              }
          end
        )

      assert expected == json_response(conn, 200)
    end
  end

  describe "POST /:submissionid/:questionid, staff" do
    @tag authenticate: :staff
    test "successful", %{conn: conn} do
      %{course: course, grader: grader, answers: answers} = seed_db(conn)

      grader_id = grader.id

      answer = List.first(answers)

      conn =
        post(conn, build_url(course.id, answer.submission.id, answer.question.id), %{
          "grading" => %{
            "xpAdjustment" => -10
          }
        })

      assert response(conn, 200) == "OK"

      assert %{
               xp_adjustment: -10,
               grader_id: ^grader_id
             } = Repo.get(Answer, answer.id)
    end

    @tag authenticate: :staff
    test "invalid xp_adjustment fails", %{conn: conn} do
      %{course: course, answers: answers} = seed_db(conn)

      answer = List.first(answers)

      conn =
        post(conn, build_url(course.id, answer.submission.id, answer.question.id), %{
          "grading" => %{"xpAdjustment" => -9_999_999_999}
        })

      assert response(conn, 400) ==
               "xp_adjustment must make total be between 0 and question.max_xp"
    end

    @tag authenticate: :staff
    test "missing parameter", %{conn: conn} do
      course_id = conn.assigns.course_id
      conn = post(conn, build_url(course_id, 1, 3), %{})
      assert response(conn, 400) =~ "Missing parameter"
    end

    @tag authenticate: :staff
    test "submission is not :submitted", %{conn: conn} do
      %{course: course, grader: grader, mission: mission, questions: questions} = seed_db(conn)

      submission = insert(:submission, %{assessment: mission, status: :attempting})

      question = List.first(questions)

      answer =
        insert(:answer, %{
          grader_id: grader.id,
          xp: 1000,
          xp_adjustment: -500,
          question: question,
          submission: submission,
          answer:
            case question.type do
              :programming -> build(:programming_answer)
              :mcq -> build(:mcq_answer)
              :voting -> build(:voting_answer)
            end
        })

      conn =
        post(conn, build_url(course.id, answer.submission_id, answer.question_id), %{
          "grading" => %{
            "xpAdjustment" => -100
          }
        })

      assert response(conn, 405) =~ "Submission is not submitted yet."
    end
  end

  describe "POST /:submissionid/unsubmit, staff" do
    @tag authenticate: :staff
    test "succeeds", %{conn: conn} do
      %{course: course, config: config, grader: grader, students: students} = seed_db(conn)

      assessment =
        insert(
          :assessment,
          open_at: Timex.shift(Timex.now(), hours: -1),
          close_at: Timex.shift(Timex.now(), hours: 500),
          is_published: true,
          config: config,
          course: course
        )

      question = insert(:programming_question, assessment: assessment)
      student = List.first(students)

      submission =
        insert(:submission, assessment: assessment, student: student, status: :submitted)

      answer =
        insert(
          :answer,
          submission: submission,
          question: question,
          answer: %{code: "f => f(f);"},
          grader_id: grader.id
        )

      conn
      |> post(build_url_unsubmit(course.id, submission.id))
      |> response(200)

      submission_db = Repo.get(Submission, submission.id)
      answer_db = Repo.get(Answer, answer.id)

      assert submission_db.status == :attempted
      assert submission_db.unsubmitted_by_id === grader.id
      assert submission_db.unsubmitted_at != nil

      assert answer_db.autograding_status == :none
      assert answer_db.autograding_results == []
      assert answer_db.grader_id == grader.id
      assert answer_db.xp == 0
      assert answer_db.xp_adjustment == 0
      assert answer_db.comments == answer.comments
    end

    @tag authenticate: :staff
    test "assessments which have not been submitted should not be allowed to unsubmit", %{
      conn: conn
    } do
      %{course: course, config: config, students: students} = seed_db(conn)

      assessment =
        insert(
          :assessment,
          open_at: Timex.shift(Timex.now(), hours: -1),
          close_at: Timex.shift(Timex.now(), hours: 500),
          is_published: true,
          config: config,
          course: course
        )

      question = insert(:programming_question, assessment: assessment)
      student = List.first(students)

      submission =
        insert(:submission, assessment: assessment, student: student, status: :attempted)

      insert(
        :answer,
        submission: submission,
        question: question,
        answer: %{code: "f => f(f);"}
      )

      conn =
        conn
        |> post(build_url_unsubmit(course.id, submission.id))

      assert response(conn, 400) =~ "Assessment has not been submitted"
    end

    @tag authenticate: :staff
    test "assessment that is not open anymore cannot be unsubmitted", %{conn: conn} do
      %{course: course, config: config, students: students} = seed_db(conn)

      assessment =
        insert(
          :assessment,
          open_at: Timex.shift(Timex.now(), hours: 1),
          close_at: Timex.shift(Timex.now(), hours: 500),
          is_published: true,
          course: course,
          config: config
        )

      question = insert(:programming_question, assessment: assessment)
      student = List.first(students)

      submission =
        insert(:submission, assessment: assessment, student: student, status: :submitted)

      insert(
        :answer,
        submission: submission,
        question: question,
        answer: %{code: "f => f(f);"}
      )

      conn =
        conn
        |> post(build_url_unsubmit(course.id, submission.id))

      assert response(conn, 403) =~ "Assessment not open"
    end

    @tag authenticate: :staff
    test "avenger should not be allowed to unsubmit for students outside of their group", %{
      conn: conn
    } do
      %{course: course, config: config, students: students} = seed_db(conn)

      assessment =
        insert(
          :assessment,
          open_at: Timex.shift(Timex.now(), hours: -1),
          close_at: Timex.shift(Timex.now(), hours: 500),
          is_published: true,
          course: course,
          config: config
        )

      other_grader = insert(:course_registration, %{role: :staff, course: course})
      question = insert(:programming_question, assessment: assessment)
      student = List.first(students)

      submission =
        insert(:submission, assessment: assessment, student: student, status: :submitted)

      insert(
        :answer,
        submission: submission,
        question: question,
        answer: %{code: "f => f(f);"}
      )

      conn =
        conn
        |> sign_in(other_grader.user)
        |> post(build_url_unsubmit(course.id, submission.id))

      assert response(conn, 403) =~ "Only Avenger of student or Admin is permitted to unsubmit"
    end

    @tag authenticate: :staff
    test "avenger should be allowed to unsubmit own submissions", %{
      conn: conn
    } do
      %{course: course, config: config, grader: grader} = seed_db(conn)

      assessment =
        insert(
          :assessment,
          open_at: Timex.shift(Timex.now(), hours: -1),
          close_at: Timex.shift(Timex.now(), hours: 500),
          is_published: true,
          course: course,
          config: config
        )

      question = insert(:programming_question, assessment: assessment)

      submission =
        insert(:submission, assessment: assessment, student: grader, status: :submitted)

      insert(
        :answer,
        submission: submission,
        question: question,
        answer: %{code: "f => f(f);"}
      )

      conn =
        conn
        |> post(build_url_unsubmit(course.id, submission.id))

      assert response(conn, 200) =~ "OK"
    end

    @tag authenticate: :staff
    test "avenger should be allowed to unsubmit own closed submissions", %{
      conn: conn
    } do
      %{course: course, config: config, grader: grader} = seed_db(conn)

      assessment =
        insert(
          :assessment,
          open_at: Timex.shift(Timex.now(), hours: 1),
          close_at: Timex.shift(Timex.now(), hours: 500),
          is_published: true,
          course: course,
          config: config
        )

      question = insert(:programming_question, assessment: assessment)

      submission =
        insert(:submission, assessment: assessment, student: grader, status: :submitted)

      insert(
        :answer,
        submission: submission,
        question: question,
        answer: %{code: "f => f(f);"}
      )

      conn =
        conn
        |> post(build_url_unsubmit(course.id, submission.id))

      assert response(conn, 200) =~ "OK"
    end

    @tag authenticate: :admin
    test "admin should be allowed to unsubmit", %{
      conn: conn
    } do
      %{course: course, config: config, students: students} = seed_db(conn)

      admin = insert(:course_registration, %{role: :admin, course: course})

      assessment =
        insert(
          :assessment,
          open_at: Timex.shift(Timex.now(), hours: -1),
          close_at: Timex.shift(Timex.now(), hours: 500),
          is_published: true,
          course: course,
          config: config
        )

      question = insert(:programming_question, assessment: assessment)
      student = List.first(students)

      submission =
        insert(:submission, assessment: assessment, student: student, status: :submitted)

      answer =
        insert(
          :answer,
          submission: submission,
          question: question,
          answer: %{code: "f => f(f);"}
        )

      conn
      |> sign_in(admin.user)
      |> post(build_url_unsubmit(course.id, submission.id))

      submission_db = Repo.get(Submission, submission.id)
      answer_db = Repo.get(Answer, answer.id)

      assert submission_db.status == :attempted
      assert submission_db.unsubmitted_by_id === admin.id
      assert submission_db.unsubmitted_at != nil

      assert answer_db.autograding_status == :none
      assert answer_db.autograding_results == []
      assert answer_db.grader_id == nil
      assert answer_db.xp == 0
      assert answer_db.xp_adjustment == 0
    end
  end

  describe "GET /, admin" do
    @tag authenticate: :staff
    test "can see all submissions", %{conn: conn} do
      %{
        course: course,
        mission: mission,
        submissions: submissions
      } = seed_db(conn)

      admin = insert(:course_registration, course: course, role: :admin)

      conn =
        conn
        |> sign_in(admin.user)
        |> get(build_url(course.id))

      expected =
        Enum.map(submissions, fn submission ->
          %{
            "xp" => 5000,
            "xpAdjustment" => -2500,
            "xpBonus" => 100,
            "id" => submission.id,
            "student" => %{
              "name" => submission.student.user.name,
              "id" => submission.student.id,
              "groupName" => submission.student.group.name,
              "groupLeaderId" => submission.student.group.leader_id
            },
            "assessment" => %{
              "type" => mission.config.type,
              "isManuallyGraded" => mission.config.is_manually_graded,
              "maxXp" => 5000,
              "id" => mission.id,
              "title" => mission.title,
              "questionCount" => 5
            },
            "status" => Atom.to_string(submission.status),
            "gradedCount" => 5,
            "unsubmittedBy" => nil,
            "unsubmittedAt" => nil
          }
        end)

      assert expected == Enum.sort_by(json_response(conn, 200), & &1["id"])
    end
  end

  describe "GET /?group=true, admin" do
    @tag authenticate: :admin
    test "successful", %{conn: conn} do
      %{
        course: course,
        mission: mission,
        submissions: submissions
      } = seed_db(conn)

      conn = get(conn, build_url(course.id), %{"group" => "true"})

      expected =
        Enum.map(submissions, fn submission ->
          %{
            "xp" => 5000,
            "xpAdjustment" => -2500,
            "xpBonus" => 100,
            "id" => submission.id,
            "student" => %{
              "name" => submission.student.user.name,
              "id" => submission.student.id,
              "groupName" => submission.student.group.name,
              "groupLeaderId" => submission.student.group.leader_id
            },
            "assessment" => %{
              "type" => mission.config.type,
              "isManuallyGraded" => mission.config.is_manually_graded,
              "maxXp" => 5000,
              "id" => mission.id,
              "title" => mission.title,
              "questionCount" => 5
            },
            "status" => Atom.to_string(submission.status),
            "gradedCount" => 5,
            "unsubmittedBy" => nil,
            "unsubmittedAt" => nil
          }
        end)

      assert expected == Enum.sort_by(json_response(conn, 200), & &1["id"])
    end
  end

  describe "GET /:submissionid, admin" do
    @tag authenticate: :admin
    test "successful", %{conn: conn} do
      %{
        course: course,
        grader: grader,
        submissions: submissions,
        answers: answers
      } = seed_db(conn)

      submission = List.first(submissions)

      conn = get(conn, build_url(course.id, submission.id))

      expected =
        answers
        |> Enum.filter(&(&1.submission.id == submission.id))
        |> Enum.sort_by(& &1.question.display_order)
        |> Enum.map(
          &case &1.question.type do
            :programming ->
              %{
                "question" => %{
                  "prepend" => &1.question.question.prepend,
                  "postpend" => &1.question.question.postpend,
                  "testcases" =>
                    Enum.map(
                      &1.question.question.public,
                      fn testcase ->
                        for {k, v} <- testcase,
                            into: %{"type" => "public"},
                            do: {Atom.to_string(k), v}
                      end
                    ) ++
                      Enum.map(
                        &1.question.question.private,
                        fn testcase ->
                          for {k, v} <- testcase,
                              into: %{"type" => "private"},
                              do: {Atom.to_string(k), v}
                        end
                      ),
                  "solutionTemplate" => &1.question.question.template,
                  "type" => "#{&1.question.type}",
                  "blocking" => &1.question.blocking,
                  "id" => &1.question.id,
                  "library" => %{
                    "chapter" => &1.question.library.chapter,
                    "globals" => &1.question.library.globals,
                    "external" => %{
                      "name" => "#{&1.question.library.external.name}",
                      "symbols" => &1.question.library.external.symbols
                    }
                  },
                  "maxXp" => &1.question.max_xp,
                  "content" => &1.question.question.content,
                  "answer" => &1.answer.code,
                  "autogradingStatus" => Atom.to_string(&1.autograding_status),
                  "autogradingResults" => &1.autograding_results
                },
                "solution" => &1.question.question.solution,
                "grade" => %{
                  "xp" => &1.xp,
                  "xpAdjustment" => &1.xp_adjustment,
                  "grader" => %{
                    "name" => grader.user.name,
                    "id" => grader.id
                  },
                  "gradedAt" => format_datetime(&1.updated_at),
                  "comments" => &1.comments
                },
                "student" => %{
                  "name" => &1.submission.student.user.name,
                  "id" => &1.submission.student.id
                }
              }

            :mcq ->
              %{
                "question" => %{
                  "type" => "#{&1.question.type}",
                  "blocking" => &1.question.blocking,
                  "id" => &1.question.id,
                  "library" => %{
                    "chapter" => &1.question.library.chapter,
                    "globals" => &1.question.library.globals,
                    "external" => %{
                      "name" => "#{&1.question.library.external.name}",
                      "symbols" => &1.question.library.external.symbols
                    }
                  },
                  "content" => &1.question.question.content,
                  "answer" => &1.answer.choice_id,
                  "maxXp" => &1.question.max_xp,
                  "choices" =>
                    for choice <- &1.question.question.choices do
                      %{
                        "content" => choice.content,
                        "hint" => choice.hint,
                        "id" => choice.choice_id
                      }
                    end,
                  "autogradingStatus" => Atom.to_string(&1.autograding_status),
                  "autogradingResults" => &1.autograding_results
                },
                "solution" => "",
                "grade" => %{
                  "xp" => &1.xp,
                  "xpAdjustment" => &1.xp_adjustment,
                  "grader" => %{
                    "name" => grader.user.name,
                    "id" => grader.id
                  },
                  "gradedAt" => format_datetime(&1.updated_at),
                  "comments" => &1.comments
                },
                "student" => %{
                  "name" => &1.submission.student.user.name,
                  "id" => &1.submission.student.id
                }
              }

            :voting ->
              %{
                "question" => %{
                  "prepend" => &1.question.question.prepend,
                  "solutionTemplate" => &1.question.question.template,
                  "type" => "#{&1.question.type}",
                  "blocking" => &1.question.blocking,
                  "id" => &1.question.id,
                  "library" => %{
                    "chapter" => &1.question.library.chapter,
                    "globals" => &1.question.library.globals,
                    "external" => %{
                      "name" => "#{&1.question.library.external.name}",
                      "symbols" => &1.question.library.external.symbols
                    }
                  },
                  "maxXp" => &1.question.max_xp,
                  "content" => &1.question.question.content,
                  "autogradingStatus" => Atom.to_string(&1.autograding_status),
                  "autogradingResults" => &1.autograding_results,
                  "answer" => nil,
                  "contestEntries" => [],
                  "contestLeaderboard" => []
                },
                "grade" => %{
                  "xp" => &1.xp,
                  "xpAdjustment" => &1.xp_adjustment,
                  "grader" => %{
                    "name" => grader.user.name,
                    "id" => grader.id
                  },
                  "gradedAt" => format_datetime(&1.updated_at),
                  "comments" => &1.comments
                },
                "student" => %{
                  "name" => &1.submission.student.user.name,
                  "id" => &1.submission.student.id
                },
                "solution" => ""
              }
          end
        )

      assert expected == json_response(conn, 200)
    end
  end

  describe "POST /:submissionid/:questionid, admin" do
    @tag authenticate: :admin
    test "succeeds", %{conn: conn} do
      %{course: course, answers: answers} = seed_db(conn)

      answer = List.first(answers)

      conn =
        post(conn, build_url(course.id, answer.submission.id, answer.question.id), %{
          "grading" => %{"xpAdjustment" => -10}
        })

      assert response(conn, 200) == "OK"
      assert %{xp_adjustment: -10} = Repo.get(Answer, answer.id)
    end

    @tag authenticate: :admin
    test "missing parameter", %{conn: conn} do
      course_id = conn.assigns.course_id
      conn = post(conn, build_url(course_id, 1, 3), %{})
      assert response(conn, 400) =~ "Missing parameter"
    end
  end

  describe "GET /summary" do
    @tag authenticate: :admin
    @tag :skip
    test "admin can see summary", %{conn: conn} do
      %{
        course: course,
        submissions: submissions,
        group: group,
        grader: grader,
        answers: answers
      } = seed_db(conn)

      conn = get(conn, build_url_summary(course.id))

      expected = [
        %{
          "groupName" => group.name,
          "leaderName" => grader.user.name,
          "submittedMissions" => count_submissions(submissions, answers, "mission"),
          "submittedSidequests" => count_submissions(submissions, answers, "sidequest"),
          "ungradedMissions" => count_submissions(submissions, answers, "mission", true),
          "ungradedSidequests" => count_submissions(submissions, answers, "sidequest", true)
        }
      ]

      assert expected == Enum.sort_by(json_response(conn, 200), & &1["groupName"])
    end

    @tag authenticate: :student
    @tag :skip
    test "student cannot see summary", %{conn: conn} do
      conn = get(conn, build_url_summary())
      assert response(conn, 403) =~ "Forbidden"
    end
  end

  describe "POST /grading/:submissionid/autograde" do
    setup %{conn: conn} do
      %{
        course: course,
        submissions: [submission, _]
      } = seed_db(conn)

      %{course: course, submission: submission}
    end

    @tag authenticate: :staff
    test "staff can re-autograde submissions", %{
      conn: conn,
      course: course,
      submission: submission
    } do
      with_mock Cadet.Autograder.GradingJob,
        force_grade_individual_submission: fn in_sub, _ -> assert submission.id == in_sub.id end do
        assert conn |> post(build_url_autograde(course.id, submission.id)) |> response(204)
      end
    end

    @tag authenticate: :student
    test "student cannot re-autograde", %{conn: conn, course: course, submission: submission} do
      assert conn |> post(build_url_autograde(course.id, submission.id)) |> response(403)
    end

    @tag authenticate: :student
    test "fails if not found", %{conn: conn, course: course} do
      assert conn |> post(build_url_autograde(course.id, 2_147_483_647)) |> response(403)
    end
  end

  describe "POST /grading/:submissionid/:questionid/autograde" do
    setup %{conn: conn} do
      %{
        course: course,
        submissions: [submission | _],
        questions: [question | _]
      } = seed_db(conn)

      %{course: course, submission: submission, question: question}
    end

    @tag authenticate: :staff
    test "staff can re-autograde questions", %{
      conn: conn,
      course: course,
      submission: submission,
      question: question
    } do
      with_mock Cadet.Autograder.GradingJob,
        grade_answer: fn in_a, in_q, _ ->
          assert question.id == in_q.id
          assert question.id == in_a.question_id
        end do
        assert conn
               |> post(build_url_autograde(course.id, submission.id, question.id))
               |> response(204)
      end
    end

    @tag authenticate: :student
    test "student cannot re-autograde", %{
      conn: conn,
      course: course,
      submission: submission,
      question: question
    } do
      assert conn
             |> post(build_url_autograde(course.id, submission.id, question.id))
             |> response(403)
    end

    @tag authenticate: :student
    test "fails if not found", %{conn: conn, course: course} do
      assert conn |> post(build_url_autograde(course.id, 2_147_483_647, 123_456)) |> response(403)
    end
  end

  defp count_submissions(submissions, answers, type, only_ungraded \\ false) do
    submissions
    |> Enum.filter(fn s ->
      s.status == :submitted and s.assessment.type == type and
        (not only_ungraded or
           answers
           |> Enum.filter(fn a -> a.submission == s and is_nil(a.grader_id) end)
           |> length() > 0)
    end)
    |> length()
  end

  defp build_url_summary, do: "/v2/admin/grading/summary"
  # old
  defp build_url(course_id), do: "/v2/courses/#{course_id}/admin/grading/"
  defp build_url_summary(course_id), do: "/v2/courses/#{course_id}/admin/grading/summary"
  defp build_url(course_id, submission_id), do: "#{build_url(course_id)}#{submission_id}"

  defp build_url(course_id, submission_id, question_id),
    do: "#{build_url(course_id, submission_id)}/#{question_id}"

  defp build_url_unsubmit(course_id, submission_id),
    do: "#{build_url(course_id, submission_id)}/unsubmit"

  defp build_url_autograde(course_id, submission_id),
    do: "#{build_url(course_id, submission_id)}/autograde"

  defp build_url_autograde(course_id, submission_id, question_id),
    do: "#{build_url(course_id, submission_id, question_id)}/autograde"

  defp seed_db(conn, override_grader \\ nil) do
    grader = override_grader || conn.assigns[:test_cr]

    course = grader.course
    assessment_config = insert(:assessment_config, %{course: course})

    group = insert(:group, %{course: course, leader_id: grader.id, leader: grader})

    students = insert_list(5, :course_registration, %{course: course, group: group})

    mission =
      insert(:assessment, %{
        title: "mission",
        course: course,
        config: assessment_config,
        is_published: true
      })

    questions =
      for index <- 0..2 do
        # insert with display order in reverse
        insert(:programming_question, %{
          assessment: mission,
          max_xp: 1000,
          display_order: 5 - index
        })
      end ++
        [
          insert(:mcq_question, %{
            assessment: mission,
            max_xp: 1000,
            display_order: 2
          })
        ] ++
        [
          insert(:voting_question, %{
            assessment: mission,
            max_xp: 1000,
            display_order: 1
          })
        ]

    submissions =
      students
      |> Enum.take(2)
      |> Enum.map(
        &insert(:submission, %{
          assessment: mission,
          student: &1,
          xp_bonus: 100,
          status: :submitted
        })
      )

    answers =
      for submission <- submissions,
          question <- questions do
        insert(:answer, %{
          grader_id: grader.id,
          xp: 1000,
          xp_adjustment: -500,
          question: question,
          submission: submission,
          answer:
            case question.type do
              :programming -> build(:programming_answer)
              :mcq -> build(:mcq_answer)
              :voting -> build(:voting_answer)
            end
        })
      end

    %{
      course: course,
      config: assessment_config,
      grader: grader,
      group: group,
      students: students,
      mission: mission,
      questions: questions,
      submissions: submissions,
      answers: answers
    }
  end
end
