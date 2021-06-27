defmodule CadetWeb.AnswerControllerTest do
  use CadetWeb.ConnCase

  import Ecto.Query

  alias Cadet.Assessments.{Answer, Submission, SubmissionVotes}
  alias Cadet.Repo
  alias CadetWeb.AnswerController

  test "swagger" do
    AnswerController.swagger_definitions()
    AnswerController.swagger_path_submit(nil)
  end

  setup do
    course = insert(:course)
    config = insert(:assessment_config, %{course: course})
    assessment = insert(:assessment, %{is_published: true, course: course, config: config})
    mcq_question = insert(:mcq_question, %{assessment: assessment})
    programming_question = insert(:programming_question, %{assessment: assessment})
    voting_question = insert(:voting_question, %{assessment: assessment})

    %{
      assessment: assessment,
      mcq_question: mcq_question,
      programming_question: programming_question,
      voting_question: voting_question
    }
  end

  describe "POST /assessments/question/{questionId}/answer/, Unauthenticated" do
    test "is disallowed", %{conn: conn, mcq_question: question} do
      course = insert(:course)
      conn = post(conn, build_url(course.id, question.id), %{answer: 5})

      assert response(conn, 401) =~ "Unauthorised"
    end
  end

  for role <- ~w(student staff admin)a do
    describe "POST /assessments/question/{questionId}/answer/, #{role}" do
      @tag authenticate: role
      test "valid params first submission is successful", %{
        conn: conn,
        assessment: assessment,
        mcq_question: mcq_question,
        programming_question: programming_question,
        voting_question: voting_question
      } do
        course_reg = conn.assigns.test_cr
        course_id = conn.assigns.course_id
        mcq_conn = post(conn, build_url(course_id, mcq_question.id), %{answer: 5})
        assert response(mcq_conn, 200) =~ "OK"
        assert get_answer_value(mcq_question, assessment, course_reg) == 5

        programming_conn =
          post(conn, build_url(course_id, programming_question.id), %{answer: "hello world"})

        assert response(programming_conn, 200) =~ "OK"
        assert get_answer_value(programming_question, assessment, course_reg) == "hello world"

        contest_submission = insert(:submission)

        Repo.insert(%SubmissionVotes{
          voter_id: course_reg.id,
          question_id: voting_question.id,
          submission_id: contest_submission.id
        })

        voting_conn =
          post(conn, build_url(course_id, voting_question.id), %{
            answer: [
              %{"answer" => "hello world", "submission_id" => contest_submission.id, "rank" => 3}
            ]
          })

        assert response(voting_conn, 200) =~ "OK"
        rank = get_rank_for_submission_vote(voting_question, course_reg, contest_submission)
        assert rank == 3
      end

      @tag authenticate: role
      test "valid params update submission is successful", %{
        conn: conn,
        assessment: assessment,
        mcq_question: mcq_question,
        programming_question: programming_question,
        voting_question: voting_question
      } do
        course_reg = conn.assigns.test_cr
        course_id = conn.assigns.course_id
        mcq_conn = post(conn, build_url(course_id, mcq_question.id), %{answer: 5})
        assert response(mcq_conn, 200) =~ "OK"
        assert get_answer_value(mcq_question, assessment, course_reg) == 5

        updated_mcq_conn = post(conn, build_url(course_id, mcq_question.id), %{answer: 6})
        assert response(updated_mcq_conn, 200) =~ "OK"
        assert get_answer_value(mcq_question, assessment, course_reg) == 6

        programming_conn =
          post(conn, build_url(course_id, programming_question.id), %{answer: "hello world"})

        assert response(programming_conn, 200) =~ "OK"
        assert get_answer_value(programming_question, assessment, course_reg) == "hello world"

        updated_programming_conn =
          post(conn, build_url(course_id, programming_question.id), %{answer: "hello_world"})

        assert response(updated_programming_conn, 200) =~ "OK"
        assert get_answer_value(programming_question, assessment, course_reg) == "hello_world"

        contest_submission = insert(:submission)

        Repo.insert(%SubmissionVotes{
          voter_id: course_reg.id,
          question_id: voting_question.id,
          submission_id: contest_submission.id
        })

        voting_conn =
          post(conn, build_url(course_id, voting_question.id), %{
            answer: [
              %{"answer" => "hello world", "submission_id" => contest_submission.id, "rank" => 3}
            ]
          })

        assert response(voting_conn, 200) =~ "OK"

        updated_voting_conn =
          post(conn, build_url(course_id, voting_question.id), %{
            answer: [
              %{"answer" => "hello world", "submission_id" => contest_submission.id, "rank" => 5}
            ]
          })

        assert response(updated_voting_conn, 200) =~ "OK"

        rank = get_rank_for_submission_vote(voting_question, course_reg, contest_submission)
        assert rank == 5
      end

      @tag authenticate: role
      test "answering all questions updates submission status to attempted", %{
        conn: conn,
        assessment: assessment,
        mcq_question: mcq_question,
        programming_question: programming_question,
        voting_question: voting_question
      } do
        course_reg = conn.assigns.test_cr
        course_id = conn.assigns.course_id
        post(conn, build_url(course_id, mcq_question.id), %{answer: 5})
        post(conn, build_url(course_id, programming_question.id), %{answer: "hello world"})
        contest_submission = insert(:submission)

        Repo.insert(%SubmissionVotes{
          voter_id: course_reg.id,
          question_id: voting_question.id,
          submission_id: contest_submission.id
        })

        post(conn, build_url(course_id, voting_question.id), %{
          answer: [
            %{"answer" => "hello world", "submission_id" => contest_submission.id, "rank" => 3}
          ]
        })

        assessment = assessment |> Repo.preload(:questions)

        submission =
          Submission
          |> where(student_id: ^course_reg.id)
          |> where(assessment_id: ^assessment.id)
          |> Repo.one!()

        assert submission.status == :attempted

        # should not affect submission changes
        conn = post(conn, build_url(course_id, mcq_question.id), %{answer: 5})
        assert response(conn, 200) =~ "OK"
      end

      if role == :student do
        @tag authenticate: role
        test "answering submitted question is unsuccessful", %{
          conn: conn,
          assessment: assessment,
          mcq_question: mcq_question
        } do
          course_reg = conn.assigns.test_cr
          course_id = conn.assigns.course_id

          insert(:submission, %{assessment: assessment, student: course_reg, status: :submitted})
          conn = post(conn, build_url(course_id, mcq_question.id), %{answer: 5})

          assert response(conn, 403) == "Assessment submission already finalised"
        end
      else
        @tag authenticate: role
        test "answering submitted question is successful", %{
          conn: conn,
          assessment: assessment,
          mcq_question: mcq_question
        } do
          course_reg = conn.assigns.test_cr
          course_id = conn.assigns.course_id

          insert(:submission, %{assessment: assessment, student: course_reg, status: :submitted})
          conn = post(conn, build_url(course_id, mcq_question.id), %{answer: 5})

          assert response(conn, 200) == "OK"
        end
      end

      @tag authenticate: role
      test "invalid params first submission is unsuccessful", %{
        conn: conn,
        assessment: assessment,
        mcq_question: mcq_question,
        programming_question: programming_question,
        voting_question: voting_question
      } do
        course_reg = conn.assigns.test_cr
        course_id = conn.assigns.course_id

        missing_answer_conn =
          post(conn, build_url(course_id, programming_question.id), %{answ: 5})

        assert response(missing_answer_conn, 400) == "Missing or invalid parameter(s)"
        assert is_nil(get_answer_value(mcq_question, assessment, course_reg))

        mcq_conn = post(conn, build_url(course_id, programming_question.id), %{answer: 5})
        assert response(mcq_conn, 400) == "Missing or invalid parameter(s)"
        assert is_nil(get_answer_value(mcq_question, assessment, course_reg))

        programming_conn =
          post(conn, build_url(course_id, mcq_question.id), %{answer: "hello world"})

        assert response(programming_conn, 400) == "Missing or invalid parameter(s)"
        assert is_nil(get_answer_value(programming_question, assessment, course_reg))

        contest_submission = insert(:submission)

        Repo.insert(%SubmissionVotes{
          voter_id: course_reg.id,
          question_id: voting_question.id,
          submission_id: contest_submission.id
        })

        voting_conn =
          post(conn, build_url(course_id, voting_question.id), %{
            answer: [
              %{
                "answer" => "hello world",
                "submission_id" => contest_submission.id,
                "rank" => "a"
              }
            ]
          })

        assert response(voting_conn, 400) ==
                 "Invalid vote or vote is not unique! Vote is not saved."
      end

      @tag authenticate: role
      test "update duplicate rank in submission_votes is unsuccessful", %{
        conn: conn,
        voting_question: voting_question
      } do
        course_reg = conn.assigns.test_cr
        course_id = conn.assigns.course_id

        first_contest_submission = insert(:submission)
        second_contest_submission = insert(:submission)

        Repo.insert(%SubmissionVotes{
          voter_id: course_reg.id,
          question_id: voting_question.id,
          submission_id: first_contest_submission.id,
          rank: 1
        })

        Repo.insert(%SubmissionVotes{
          voter_id: course_reg.id,
          question_id: voting_question.id,
          submission_id: second_contest_submission.id,
          rank: 2
        })

        voting_conn =
          post(conn, build_url(course_id, voting_question.id), %{
            answer: [
              %{
                "answer" => "hello world",
                "submission_id" => first_contest_submission.id,
                "rank" => 3
              },
              %{
                "answer" => "hello world",
                "submission_id" => second_contest_submission.id,
                "rank" => 3
              }
            ]
          })

        assert response(voting_conn, 400) ==
                 "Invalid vote or vote is not unique! Vote is not saved."
      end
    end
  end

  @tag authenticate: :student
  test "invalid params missing question is unsuccessful", %{
    conn: conn,
    assessment: assessment,
    mcq_question: mcq_question
  } do
    course_reg = conn.assigns.test_cr
    course_id = conn.assigns.course_id
    {:ok, _} = Repo.delete(mcq_question)

    conn = post(conn, build_url(course_id, mcq_question.id), %{answer: 5})
    assert response(conn, 404) == "Question not found"
    assert is_nil(get_answer_value(mcq_question, assessment, course_reg))
  end

  @tag authenticate: :student
  test "invalid params not open submission is unsuccessful", %{conn: conn} do
    course_reg = conn.assigns.test_cr
    course_id = conn.assigns.course_id

    before_open_at_assessment =
      insert(:assessment, %{
        open_at: Timex.shift(Timex.now(), days: 5),
        close_at: Timex.shift(Timex.now(), days: 10)
      })

    before_open_at_question = insert(:mcq_question, %{assessment: before_open_at_assessment})

    before_open_at_conn =
      post(conn, build_url(course_id, before_open_at_question.id), %{answer: 5})

    assert response(before_open_at_conn, 403) == "Assessment not open"

    assert is_nil(
             get_answer_value(before_open_at_question, before_open_at_assessment, course_reg)
           )

    after_close_at_assessment =
      insert(:assessment, %{
        open_at: Timex.shift(Timex.now(), days: -10),
        close_at: Timex.shift(Timex.now(), days: -5)
      })

    after_close_at_question = insert(:mcq_question, %{assessment: after_close_at_assessment})

    after_close_at_conn =
      post(conn, build_url(course_id, after_close_at_question.id), %{answer: 5})

    assert response(after_close_at_conn, 403) == "Assessment not open"

    assert is_nil(
             get_answer_value(after_close_at_question, after_close_at_assessment, course_reg)
           )

    unpublished_assessment = insert(:assessment, %{is_published: false})

    unpublished_question = insert(:mcq_question, %{assessment: unpublished_assessment})

    unpublished_conn = post(conn, build_url(course_id, unpublished_question.id), %{answer: 5})
    assert response(unpublished_conn, 403) == "Assessment not open"
    assert is_nil(get_answer_value(unpublished_question, unpublished_assessment, course_reg))
  end

  defp build_url(course_id, question_id) do
    "/v2/courses/#{course_id}/assessments/question/#{question_id}/answer/"
  end

  defp get_answer_value(question, assessment, course_reg) do
    answer =
      Answer
      |> where(question_id: ^question.id)
      |> join(:inner, [a], s in assoc(a, :submission))
      |> where([a, s], s.student_id == ^course_reg.id)
      |> where([a, s], s.assessment_id == ^assessment.id)
      |> Repo.one()

    if answer do
      case question.type do
        :mcq -> Map.get(answer.answer, "choice_id")
        :programming -> Map.get(answer.answer, "code")
      end
    end
  end

  defp get_rank_for_submission_vote(question, course_reg, submission) do
    SubmissionVotes
    |> where(question_id: ^question.id)
    |> where(voter_id: ^course_reg.id)
    |> where(submission_id: ^submission.id)
    |> select([sv], sv.rank)
    |> Repo.one()
  end
end
