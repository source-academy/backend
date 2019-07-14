defmodule CadetWeb.GradingControllerTest do
  use CadetWeb.ConnCase

  alias Cadet.Assessments.{Answer, Submission}
  alias Cadet.Repo
  alias CadetWeb.GradingController

  test "swagger" do
    GradingController.swagger_definitions()
    GradingController.swagger_path_index(nil)
    GradingController.swagger_path_show(nil)
    GradingController.swagger_path_update(nil)
  end

  describe "GET /, unauthenticated" do
    test "unauthorized", %{conn: conn} do
      conn = get(conn, build_url())
      assert response(conn, 401) =~ "Unauthorised"
    end
  end

  describe "GET /:submissionid, unauthenticated" do
    test "unauthorized", %{conn: conn} do
      conn = get(conn, build_url(1))
      assert response(conn, 401) =~ "Unauthorised"
    end
  end

  describe "POST /:submissionid/:questionid, unauthenticated" do
    test "unauthorized", %{conn: conn} do
      conn = post(conn, build_url(1, 3), %{})
      assert response(conn, 401) =~ "Unauthorised"
    end
  end

  describe "GET /:submissionid/unsubmit, unauthenticated" do
    test "unauthorized", %{conn: conn} do
      conn = post(conn, build_url_unsubmit(1))
      assert response(conn, 401) =~ "Unauthorised"
    end
  end

  describe "GET /, student" do
    @tag authenticate: :student
    test "unauthorized", %{conn: conn} do
      conn = get(conn, build_url())
      assert response(conn, 401) =~ "User is not permitted to grade."
    end
  end

  describe "GET /?group=true, student" do
    @tag authenticate: :student
    test "unauthorized", %{conn: conn} do
      conn = get(conn, build_url(), %{"group" => "true"})
      assert response(conn, 401) =~ "User is not permitted to grade."
    end
  end

  describe "GET /:submissionid, student" do
    @tag authenticate: :student
    test "unauthorized", %{conn: conn} do
      conn = get(conn, build_url(1))
      assert response(conn, 401) =~ "User is not permitted to grade."
    end
  end

  describe "POST /:submissionid/:questionid, student" do
    @tag authenticate: :student
    test "unauthorized", %{conn: conn} do
      conn = post(conn, build_url(1, 3), %{"grading" => %{}})
      assert response(conn, 401) =~ "User is not permitted to grade."
    end

    @tag authenticate: :student
    test "missing parameter", %{conn: conn} do
      conn = post(conn, build_url(1, 3), %{})
      assert response(conn, 400) =~ "Missing parameter"
    end
  end

  describe "GET /:submissionid/unsubmit, student" do
    @tag authenticate: :student
    test "unauthorized", %{conn: conn} do
      conn = post(conn, build_url_unsubmit(1))
      assert response(conn, 403) =~ "User is not permitted to unsubmit questions"
    end
  end

  describe "GET /, staff" do
    @tag authenticate: :staff
    test "avenger gets to see all students submissions", %{conn: conn} do
      %{
        mission: mission,
        submissions: submissions
      } = seed_db(conn)

      conn = get(conn, build_url())

      expected =
        Enum.map(submissions, fn submission ->
          %{
            "xp" => 4000,
            "xpAdjustment" => -2000,
            "xpBonus" => 100,
            "grade" => 800,
            "adjustment" => -400,
            "id" => submission.id,
            "student" => %{
              "name" => submission.student.name,
              "id" => submission.student.id
            },
            "assessment" => %{
              "type" => "mission",
              "maxGrade" => 800,
              "maxXp" => 4000,
              "id" => mission.id,
              "title" => mission.title,
              "coverImage" => mission.cover_picture
            },
            "groupName" => submission.student.group.name,
            "status" => Atom.to_string(submission.status),
            "questionCount" => 4,
            "gradedCount" => 4,
            "gradingStatus" => "excluded",
            "unsubmittedBy" => nil,
            "unsubmittedAt" => nil
          }
        end)

      assert expected == Enum.sort_by(json_response(conn, 200), & &1["id"])
    end

    @tag authenticate: :staff
    test "pure mentor gets to see all students submissions", %{conn: conn} do
      %{mentor: mentor, submissions: submissions, mission: mission} = seed_db(conn)

      conn =
        conn
        |> sign_in(mentor)
        |> get(build_url())

      expected =
        Enum.map(submissions, fn submission ->
          %{
            "xp" => 4000,
            "xpAdjustment" => -2000,
            "xpBonus" => 100,
            "grade" => 800,
            "adjustment" => -400,
            "id" => submission.id,
            "student" => %{
              "name" => submission.student.name,
              "id" => submission.student.id
            },
            "assessment" => %{
              "type" => "mission",
              "maxGrade" => 800,
              "maxXp" => 4000,
              "id" => mission.id,
              "title" => mission.title,
              "coverImage" => mission.cover_picture
            },
            "groupName" => submission.student.group.name,
            "status" => Atom.to_string(submission.status),
            "questionCount" => 4,
            "gradedCount" => 4,
            "gradingStatus" => "excluded",
            "unsubmittedAt" => nil,
            "unsubmittedBy" => nil
          }
        end)

      assert expected == Enum.sort_by(json_response(conn, 200), & &1["id"])
    end
  end

  describe "GET /?group=true, staff" do
    @tag authenticate: :staff
    test "staff not leading a group to get empty", %{conn: conn} do
      seed_db(conn)

      resp =
        conn
        |> sign_in(insert(:user, role: :staff))
        |> get(build_url(), %{"group" => "true"})
        |> json_response(200)

      assert resp == []
    end

    @tag authenticate: :staff
    test "filtered by its own group", %{conn: conn} do
      %{
        mission: mission,
        submissions: submissions
      } = seed_db(conn)

      # just to insert more submissions
      seed_db(conn, insert(:user, role: :staff))

      conn = get(conn, build_url(), %{"group" => "true"})

      expected =
        Enum.map(submissions, fn submission ->
          %{
            "xp" => 4000,
            "xpAdjustment" => -2000,
            "xpBonus" => 100,
            "grade" => 800,
            "adjustment" => -400,
            "id" => submission.id,
            "student" => %{
              "name" => submission.student.name,
              "id" => submission.student.id
            },
            "assessment" => %{
              "type" => "mission",
              "maxGrade" => 800,
              "maxXp" => 4000,
              "id" => mission.id,
              "title" => mission.title,
              "coverImage" => mission.cover_picture
            },
            "groupName" => submission.student.group.name,
            "status" => Atom.to_string(submission.status),
            "questionCount" => 4,
            "gradedCount" => 4,
            "gradingStatus" => "excluded",
            "unsubmittedAt" => nil,
            "unsubmittedBy" => nil
          }
        end)

      assert expected == Enum.sort_by(json_response(conn, 200), & &1["id"])
    end
  end

  describe "GET /:submissionid, staff" do
    @tag authenticate: :staff
    test "successful", %{conn: conn} do
      %{
        grader: grader,
        submissions: submissions,
        answers: answers
      } = seed_db(conn)

      submission = List.first(submissions)

      conn = get(conn, build_url(submission.id))

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
                        for {k, v} <- testcase, into: %{}, do: {Atom.to_string(k), v}
                      end
                    ),
                  "solutionTemplate" => &1.question.question.template,
                  "type" => "#{&1.question.type}",
                  "id" => &1.question.id,
                  "library" => %{
                    "chapter" => &1.question.library.chapter,
                    "globals" => &1.question.library.globals,
                    "external" => %{
                      "name" => "#{&1.question.library.external.name}",
                      "symbols" => &1.question.library.external.symbols
                    }
                  },
                  "maxGrade" => &1.question.max_grade,
                  "maxXp" => &1.question.max_xp,
                  "content" => &1.question.question.content,
                  "answer" => &1.answer.code,
                  "autogradingStatus" => Atom.to_string(&1.autograding_status),
                  "autogradingResults" => &1.autograding_results
                },
                "solution" => &1.question.question.solution,
                "grade" => %{
                  "grade" => &1.grade,
                  "adjustment" => &1.adjustment,
                  "roomId" => &1.room_id,
                  "xp" => &1.xp,
                  "xpAdjustment" => &1.xp_adjustment,
                  "grader" => %{
                    "name" => grader.name,
                    "id" => grader.id
                  },
                  "gradedAt" => format_datetime(&1.updated_at)
                },
                "student" => %{
                  "name" => &1.submission.student.name,
                  "id" => &1.submission.student.id
                }
              }

            :mcq ->
              %{
                "question" => %{
                  "type" => "#{&1.question.type}",
                  "id" => &1.question.id,
                  "library" => %{
                    "chapter" => &1.question.library.chapter,
                    "globals" => &1.question.library.globals,
                    "external" => %{
                      "name" => "#{&1.question.library.external.name}",
                      "symbols" => &1.question.library.external.symbols
                    }
                  },
                  "maxGrade" => &1.question.max_grade,
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
                  "grade" => &1.grade,
                  "adjustment" => &1.adjustment,
                  "roomId" => &1.room_id,
                  "xp" => &1.xp,
                  "xpAdjustment" => &1.xp_adjustment,
                  "grader" => %{
                    "name" => grader.name,
                    "id" => grader.id
                  },
                  "gradedAt" => format_datetime(&1.updated_at)
                },
                "student" => %{
                  "name" => &1.submission.student.name,
                  "id" => &1.submission.student.id
                }
              }
          end
        )

      assert expected == json_response(conn, 200)
    end

    @tag authenticate: :staff
    test "pure mentor gets to view all submissions", %{conn: conn} do
      %{mentor: mentor, grader: grader, submissions: submissions, answers: answers} =
        seed_db(conn)

      submission = List.first(submissions)

      conn =
        conn
        |> sign_in(mentor)
        |> get(build_url(submission.id))

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
                        for {k, v} <- testcase, into: %{}, do: {Atom.to_string(k), v}
                      end
                    ),
                  "solutionTemplate" => &1.question.question.template,
                  "type" => "#{&1.question.type}",
                  "id" => &1.question.id,
                  "library" => %{
                    "chapter" => &1.question.library.chapter,
                    "globals" => &1.question.library.globals,
                    "external" => %{
                      "name" => "#{&1.question.library.external.name}",
                      "symbols" => &1.question.library.external.symbols
                    }
                  },
                  "maxGrade" => &1.question.max_grade,
                  "maxXp" => &1.question.max_xp,
                  "content" => &1.question.question.content,
                  "answer" => &1.answer.code,
                  "autogradingStatus" => Atom.to_string(&1.autograding_status),
                  "autogradingResults" => &1.autograding_results
                },
                "solution" => &1.question.question.solution,
                "grade" => %{
                  "grade" => &1.grade,
                  "adjustment" => &1.adjustment,
                  "roomId" => &1.room_id,
                  "xp" => &1.xp,
                  "xpAdjustment" => &1.xp_adjustment,
                  "grader" => %{
                    "name" => grader.name,
                    "id" => grader.id
                  },
                  "gradedAt" => format_datetime(&1.updated_at)
                },
                "student" => %{
                  "name" => &1.submission.student.name,
                  "id" => &1.submission.student.id
                }
              }

            :mcq ->
              %{
                "question" => %{
                  "type" => "#{&1.question.type}",
                  "id" => &1.question.id,
                  "library" => %{
                    "chapter" => &1.question.library.chapter,
                    "globals" => &1.question.library.globals,
                    "external" => %{
                      "name" => "#{&1.question.library.external.name}",
                      "symbols" => &1.question.library.external.symbols
                    }
                  },
                  "maxGrade" => &1.question.max_grade,
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
                  "grade" => &1.grade,
                  "adjustment" => &1.adjustment,
                  "roomId" => &1.room_id,
                  "xp" => &1.xp,
                  "xpAdjustment" => &1.xp_adjustment,
                  "grader" => %{
                    "name" => grader.name,
                    "id" => grader.id
                  },
                  "gradedAt" => format_datetime(&1.updated_at)
                },
                "student" => %{
                  "name" => &1.submission.student.name,
                  "id" => &1.submission.student.id
                }
              }
          end
        )

      assert expected == json_response(conn, 200)
    end
  end

  describe "POST /:submissionid/:questionid, staff" do
    @tag authenticate: :staff
    test "successful", %{conn: conn} do
      %{grader: grader, answers: answers} = seed_db(conn)

      grader_id = grader.id

      answer = List.first(answers)

      conn =
        post(conn, build_url(answer.submission.id, answer.question.id), %{
          "grading" => %{
            "adjustment" => -10,
            "xpAdjustment" => -10
          }
        })

      assert response(conn, 200) == "OK"

      assert %{
               adjustment: -10,
               xp_adjustment: -10,
               grader_id: ^grader_id
             } = Repo.get(Answer, answer.id)
    end

    @tag authenticate: :staff
    test "invalid adjustment fails", %{conn: conn} do
      %{answers: answers} = seed_db(conn)

      answer = List.first(answers)

      conn =
        post(conn, build_url(answer.submission.id, answer.question.id), %{
          "grading" => %{"adjustment" => -9_999_999_999}
        })

      assert response(conn, 400) ==
               "adjustment must make total be between 0 and question.max_grade"
    end

    @tag authenticate: :staff
    test "invalid xp_adjustment fails", %{conn: conn} do
      %{answers: answers} = seed_db(conn)

      answer = List.first(answers)

      conn =
        post(conn, build_url(answer.submission.id, answer.question.id), %{
          "grading" => %{"xpAdjustment" => -9_999_999_999}
        })

      assert response(conn, 400) ==
               "xp_adjustment must make total be between 0 and question.max_xp"
    end

    @tag authenticate: :staff
    test "staff who isn't the grader of said answer can still grade submission and grader field is updated correctly",
         %{conn: conn} do
      %{mentor: mentor, answers: answers} = seed_db(conn)

      mentor_id = mentor.id

      answer = List.first(answers)

      conn =
        conn
        |> sign_in(mentor)
        |> post(build_url(answer.submission.id, answer.question.id), %{
          "grading" => %{
            "adjustment" => -100,
            "xpAdjustment" => -100
          }
        })

      assert response(conn, 200) == "OK"

      assert %{
               adjustment: -100,
               xp_adjustment: -100,
               grader_id: ^mentor_id
             } = Repo.get(Answer, answer.id)
    end

    @tag authenticate: :staff
    test "missing parameter", %{conn: conn} do
      conn = post(conn, build_url(1, 3), %{})
      assert response(conn, 400) =~ "Missing parameter"
    end
  end

  describe "POST /:submissionid/unsubmit, staff" do
    @tag authenticate: :staff
    test "succeeds", %{conn: conn} do
      %{grader: grader, students: students} = seed_db(conn)

      assessment =
        insert(
          :assessment,
          open_at: Timex.shift(Timex.now(), hours: -1),
          close_at: Timex.shift(Timex.now(), hours: 500),
          is_published: true,
          type: :mission
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
      |> sign_in(grader)
      |> post(build_url_unsubmit(submission.id))
      |> response(200)

      submission_db = Repo.get(Submission, submission.id)
      answer_db = Repo.get(Answer, answer.id)

      assert submission_db.status == :attempted
      assert submission_db.unsubmitted_by_id === grader.id
      assert submission_db.unsubmitted_at != nil

      assert answer_db.room_id == answer.room_id
      assert answer_db.autograding_status == :none
      assert answer_db.autograding_results == []
      assert answer_db.grader_id == nil
      assert answer_db.xp == 0
      assert answer_db.xp_adjustment == 0
      assert answer_db.grade == 0
      assert answer_db.adjustment == 0
    end

    @tag authenticate: :staff
    test "assessments which have not been submitted should not be allowed to unsubmit", %{
      conn: conn
    } do
      %{grader: grader, students: students} = seed_db(conn)

      assessment =
        insert(
          :assessment,
          open_at: Timex.shift(Timex.now(), hours: -1),
          close_at: Timex.shift(Timex.now(), hours: 500),
          is_published: true,
          type: :mission
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
        |> sign_in(grader)
        |> post(build_url_unsubmit(submission.id))

      assert response(conn, 400) =~ "Assessment has not been submitted"
    end

    @tag authenticate: :staff
    test "assessment that is not open anymore cannot be unsubmitted", %{conn: conn} do
      %{grader: grader, students: students} = seed_db(conn)

      assessment =
        insert(
          :assessment,
          open_at: Timex.shift(Timex.now(), hours: 1),
          close_at: Timex.shift(Timex.now(), hours: 500),
          is_published: true,
          type: :mission
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
        |> sign_in(grader)
        |> post(build_url_unsubmit(submission.id))

      assert response(conn, 403) =~ "Assessment not open"
    end

    @tag authenticate: :staff
    test "avenger should not be allowed to unsubmit for students outside of their group", %{
      conn: conn
    } do
      %{students: students} = seed_db(conn)

      assessment =
        insert(
          :assessment,
          open_at: Timex.shift(Timex.now(), hours: -1),
          close_at: Timex.shift(Timex.now(), hours: 500),
          is_published: true,
          type: :mission
        )

      other_grader = insert(:user, role: :staff)
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
        |> sign_in(other_grader)
        |> post(build_url_unsubmit(submission.id))

      assert response(conn, 403) =~ "Only Avenger of student or Admin is permitted to unsubmit"
    end

    @tag authenticate: :admin
    test "admin should be allowed to unsubmit", %{
      conn: conn
    } do
      %{students: students} = seed_db(conn)

      admin = insert(:user, %{role: :admin})

      assessment =
        insert(
          :assessment,
          open_at: Timex.shift(Timex.now(), hours: -1),
          close_at: Timex.shift(Timex.now(), hours: 500),
          is_published: true,
          type: :mission
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
      |> sign_in(admin)
      |> post(build_url_unsubmit(submission.id))

      submission_db = Repo.get(Submission, submission.id)
      answer_db = Repo.get(Answer, answer.id)

      assert submission_db.status == :attempted
      assert submission_db.unsubmitted_by_id === admin.id
      assert submission_db.unsubmitted_at != nil

      assert answer_db.room_id == answer.room_id
      assert answer_db.autograding_status == :none
      assert answer_db.autograding_results == []
      assert answer_db.grader_id == nil
      assert answer_db.xp == 0
      assert answer_db.xp_adjustment == 0
      assert answer_db.grade == 0
      assert answer_db.adjustment == 0
    end
  end

  describe "GET /, admin" do
    @tag authenticate: :staff
    test "can see all submissions", %{conn: conn} do
      %{
        mission: mission,
        submissions: submissions
      } = seed_db(conn)

      admin = insert(:user, role: :admin)

      conn =
        conn
        |> sign_in(admin)
        |> get(build_url())

      expected =
        Enum.map(submissions, fn submission ->
          %{
            "xp" => 4000,
            "xpAdjustment" => -2000,
            "xpBonus" => 100,
            "grade" => 800,
            "adjustment" => -400,
            "id" => submission.id,
            "student" => %{
              "name" => submission.student.name,
              "id" => submission.student.id
            },
            "assessment" => %{
              "type" => "mission",
              "maxGrade" => 800,
              "maxXp" => 4000,
              "id" => mission.id,
              "title" => mission.title,
              "coverImage" => mission.cover_picture
            },
            "groupName" => submission.student.group.name,
            "status" => Atom.to_string(submission.status),
            "questionCount" => 4,
            "gradedCount" => 4,
            "gradingStatus" => "excluded",
            "unsubmittedAt" => nil,
            "unsubmittedBy" => nil
          }
        end)

      assert expected == Enum.sort_by(json_response(conn, 200), & &1["id"])
    end
  end

  describe "GET /?group=true, admin" do
    @tag authenticate: :admin
    test "successful", %{conn: conn} do
      %{
        mission: mission,
        submissions: submissions
      } = seed_db(conn)

      conn = get(conn, build_url(), %{"group" => "true"})

      expected =
        Enum.map(submissions, fn submission ->
          %{
            "xp" => 4000,
            "xpAdjustment" => -2000,
            "xpBonus" => 100,
            "grade" => 800,
            "adjustment" => -400,
            "id" => submission.id,
            "student" => %{
              "name" => submission.student.name,
              "id" => submission.student.id
            },
            "assessment" => %{
              "type" => "mission",
              "maxGrade" => 800,
              "maxXp" => 4000,
              "id" => mission.id,
              "title" => mission.title,
              "coverImage" => mission.cover_picture
            },
            "groupName" => submission.student.group.name,
            "status" => Atom.to_string(submission.status),
            "questionCount" => 4,
            "gradedCount" => 4,
            "gradingStatus" => "excluded",
            "unsubmittedAt" => nil,
            "unsubmittedBy" => nil
          }
        end)

      assert expected == Enum.sort_by(json_response(conn, 200), & &1["id"])
    end
  end

  describe "GET /:submissionid, admin" do
    @tag authenticate: :admin
    test "successful", %{conn: conn} do
      %{
        grader: grader,
        submissions: submissions,
        answers: answers
      } = seed_db(conn)

      submission = List.first(submissions)

      conn = get(conn, build_url(submission.id))

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
                        for {k, v} <- testcase, into: %{}, do: {Atom.to_string(k), v}
                      end
                    ),
                  "solutionTemplate" => &1.question.question.template,
                  "type" => "#{&1.question.type}",
                  "id" => &1.question.id,
                  "library" => %{
                    "chapter" => &1.question.library.chapter,
                    "globals" => &1.question.library.globals,
                    "external" => %{
                      "name" => "#{&1.question.library.external.name}",
                      "symbols" => &1.question.library.external.symbols
                    }
                  },
                  "maxGrade" => &1.question.max_grade,
                  "maxXp" => &1.question.max_xp,
                  "content" => &1.question.question.content,
                  "answer" => &1.answer.code,
                  "autogradingStatus" => Atom.to_string(&1.autograding_status),
                  "autogradingResults" => &1.autograding_results
                },
                "solution" => &1.question.question.solution,
                "grade" => %{
                  "grade" => &1.grade,
                  "adjustment" => &1.adjustment,
                  "roomId" => &1.room_id,
                  "xp" => &1.xp,
                  "xpAdjustment" => &1.xp_adjustment,
                  "grader" => %{
                    "name" => grader.name,
                    "id" => grader.id
                  },
                  "gradedAt" => format_datetime(&1.updated_at)
                },
                "student" => %{
                  "name" => &1.submission.student.name,
                  "id" => &1.submission.student.id
                }
              }

            :mcq ->
              %{
                "question" => %{
                  "type" => "#{&1.question.type}",
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
                  "maxGrade" => &1.question.max_grade,
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
                  "grade" => &1.grade,
                  "adjustment" => &1.adjustment,
                  "roomId" => &1.room_id,
                  "xp" => &1.xp,
                  "xpAdjustment" => &1.xp_adjustment,
                  "grader" => %{
                    "name" => grader.name,
                    "id" => grader.id
                  },
                  "gradedAt" => format_datetime(&1.updated_at)
                },
                "student" => %{
                  "name" => &1.submission.student.name,
                  "id" => &1.submission.student.id
                }
              }
          end
        )

      assert expected == json_response(conn, 200)
    end
  end

  describe "POST /:submissionid/:questionid, admin" do
    @tag authenticate: :admin
    test "succeeds", %{conn: conn} do
      %{answers: answers} = seed_db(conn)

      answer = List.first(answers)

      conn =
        post(conn, build_url(answer.submission.id, answer.question.id), %{
          "grading" => %{"adjustment" => -10, "room_id" => "19422040"}
        })

      assert response(conn, 200) == "OK"
      assert %{adjustment: -10, room_id: room_id} = Repo.get(Answer, answer.id)
    end

    @tag authenticate: :admin
    test "missing parameter", %{conn: conn} do
      conn = post(conn, build_url(1, 3), %{})
      assert response(conn, 400) =~ "Missing parameter"
    end
  end

  defp build_url, do: "/v1/grading/"
  defp build_url(submission_id), do: "#{build_url()}#{submission_id}/"
  defp build_url(submission_id, question_id), do: "#{build_url(submission_id)}#{question_id}"
  defp build_url_unsubmit(submission_id), do: "#{build_url(submission_id)}/unsubmit"

  defp seed_db(conn, override_grader \\ nil) do
    grader = override_grader || conn.assigns[:current_user]
    mentor = insert(:user, role: :staff)

    group =
      insert(:group, %{leader_id: grader.id, leader: grader, mentor_id: mentor.id, mentor: mentor})

    students = insert_list(5, :student, %{group: group})
    mission = insert(:assessment, %{title: "mission", type: :mission, is_published: true})

    questions =
      for index <- 0..2 do
        # insert with display order in reverse
        insert(:programming_question, %{
          assessment: mission,
          max_grade: 200,
          max_xp: 1000,
          display_order: 4 - index
        })
      end ++
        [
          insert(:mcq_question, %{
            assessment: mission,
            max_grade: 200,
            max_xp: 1000,
            display_order: 1
          })
        ]

    submissions =
      students
      |> Enum.take(2)
      |> Enum.map(&insert(:submission, %{assessment: mission, student: &1, xp_bonus: 100}))

    answers =
      for submission <- submissions,
          question <- questions do
        insert(:answer, %{
          grader_id: grader.id,
          grade: 200,
          adjustment: -100,
          xp: 1000,
          xp_adjustment: -500,
          question: question,
          submission: submission,
          answer:
            case question.type do
              :programming -> build(:programming_answer)
              :mcq -> build(:mcq_answer)
            end
        })
      end

    %{
      grader: grader,
      mentor: mentor,
      group: group,
      students: students,
      mission: mission,
      questions: questions,
      submissions: submissions,
      answers: answers
    }
  end
end
