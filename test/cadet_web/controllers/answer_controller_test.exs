defmodule CadetWeb.AnswerControllerTest do
  use CadetWeb.ConnCase

  import Ecto.Query

  alias Cadet.Assessments.{Answer, Submission}
  alias Cadet.Repo
  alias CadetWeb.AnswerController

  test "swagger" do
    AnswerController.swagger_definitions()
    AnswerController.swagger_path_submit(nil)
  end

  setup do
    assessment = insert(:assessment, %{is_published: true})
    mcq_question = insert(:mcq_question, %{assessment: assessment})
    programming_question = insert(:programming_question, %{assessment: assessment})

    %{
      assessment: assessment,
      mcq_question: mcq_question,
      programming_question: programming_question
    }
  end

  describe "POST /assessments/question/{questionId}/submit/, Unauthenticated" do
    test "is disallowed", %{conn: conn, mcq_question: question} do
      conn = post(conn, build_url(question.id), %{answer: 5})

      assert response(conn, 401) =~ "Unauthorised"
    end
  end

  describe "POST /assessments/question/{questionId}/submit/, Staff" do
    @tag authenticate: :staff
    test "is disallowed", %{conn: conn, mcq_question: question} do
      conn = post(conn, build_url(question.id), %{answer: 5})

      assert response(conn, 403) =~ "User is not permitted to answer questions"
    end
  end

  describe "POST /assessments/question/{questionId}/submit/, Admin" do
    @tag authenticate: :admin
    test "is disallowed", %{conn: conn, mcq_question: question} do
      conn = post(conn, build_url(question.id), %{answer: 5})

      assert response(conn, 403) =~ "User is not permitted to answer questions"
    end
  end

  describe "POST /assessments/question/{questionId}/submit/, Student" do
    @tag authenticate: :student
    test "valid params first submission is successful", %{
      conn: conn,
      assessment: assessment,
      mcq_question: mcq_question,
      programming_question: programming_question
    } do
      user = conn.assigns.current_user
      mcq_conn = post(conn, build_url(mcq_question.id), %{answer: 5})
      assert response(mcq_conn, 200) =~ "OK"
      assert get_answer_value(mcq_question, assessment, user) == 5

      programming_conn = post(conn, build_url(programming_question.id), %{answer: "hello world"})
      assert response(programming_conn, 200) =~ "OK"
      assert get_answer_value(programming_question, assessment, user) == "hello world"
    end

    @tag authenticate: :student
    test "valid params update submission is successful", %{
      conn: conn,
      assessment: assessment,
      mcq_question: mcq_question,
      programming_question: programming_question
    } do
      user = conn.assigns.current_user
      mcq_conn = post(conn, build_url(mcq_question.id), %{answer: 5})
      assert response(mcq_conn, 200) =~ "OK"
      assert get_answer_value(mcq_question, assessment, user) == 5

      updated_mcq_conn = post(conn, build_url(mcq_question.id), %{answer: 6})
      assert response(updated_mcq_conn, 200) =~ "OK"
      assert get_answer_value(mcq_question, assessment, user) == 6

      programming_conn = post(conn, build_url(programming_question.id), %{answer: "hello world"})
      assert response(programming_conn, 200) =~ "OK"
      assert get_answer_value(programming_question, assessment, user) == "hello world"

      updated_programming_conn =
        post(conn, build_url(programming_question.id), %{answer: "hello_world"})

      assert response(updated_programming_conn, 200) =~ "OK"
      assert get_answer_value(programming_question, assessment, user) == "hello_world"
    end

    @tag authenticate: :student
    test "answering all questions updates submission status to attempted", %{
      conn: conn,
      assessment: assessment,
      mcq_question: mcq_question,
      programming_question: programming_question
    } do
      user = conn.assigns.current_user
      post(conn, build_url(mcq_question.id), %{answer: 5})
      post(conn, build_url(programming_question.id), %{answer: "hello world"})

      assessment = assessment |> Repo.preload(:questions)

      submission =
        Submission
        |> where(student_id: ^user.id)
        |> where(assessment_id: ^assessment.id)
        |> Repo.one!()

      assert submission.status == :attempted

      # should not affect submission changes
      conn = post(conn, build_url(mcq_question.id), %{answer: 5})
      assert response(conn, 200) =~ "OK"
    end

    @tag authenticate: :student
    test "answering submitted question is unsuccessful", %{
      conn: conn,
      assessment: assessment,
      mcq_question: mcq_question
    } do
      user = conn.assigns.current_user

      insert(:submission, %{assessment: assessment, student: user, status: :submitted})
      conn = post(conn, build_url(mcq_question.id), %{answer: 5})

      assert response(conn, 403) == "Assessment submission already finalised"
    end

    @tag authenticate: :student
    test "invalid params first submission is unsuccessful", %{
      conn: conn,
      assessment: assessment,
      mcq_question: mcq_question,
      programming_question: programming_question
    } do
      user = conn.assigns.current_user
      missing_answer_conn = post(conn, build_url(programming_question.id), %{answ: 5})
      assert response(missing_answer_conn, 400) == "Missing or invalid parameter(s)"
      assert is_nil(get_answer_value(mcq_question, assessment, user))

      mcq_conn = post(conn, build_url(programming_question.id), %{answer: 5})
      assert response(mcq_conn, 400) == "Missing or invalid parameter(s)"
      assert is_nil(get_answer_value(mcq_question, assessment, user))

      programming_conn = post(conn, build_url(mcq_question.id), %{answer: "hello world"})
      assert response(programming_conn, 400) == "Missing or invalid parameter(s)"
      assert is_nil(get_answer_value(programming_question, assessment, user))
    end
  end

  @tag authenticate: :student
  test "invalid params missing question is unsuccessful", %{
    conn: conn,
    assessment: assessment,
    mcq_question: mcq_question
  } do
    user = conn.assigns.current_user
    {:ok, _} = Repo.delete(mcq_question)

    conn = post(conn, build_url(mcq_question.id), %{answer: 5})
    assert response(conn, 400) == "Question not found"
    assert is_nil(get_answer_value(mcq_question, assessment, user))
  end

  @tag authenticate: :student
  test "invalid params not open submission is unsuccessful", %{conn: conn} do
    user = conn.assigns.current_user

    before_open_at_assessment =
      insert(:assessment, %{
        open_at: Timex.shift(Timex.now(), days: 5),
        close_at: Timex.shift(Timex.now(), days: 10)
      })

    before_open_at_question = insert(:mcq_question, %{assessment: before_open_at_assessment})

    before_open_at_conn = post(conn, build_url(before_open_at_question.id), %{answer: 5})
    assert response(before_open_at_conn, 403) == "Assessment not open"
    assert is_nil(get_answer_value(before_open_at_question, before_open_at_assessment, user))

    after_close_at_assessment =
      insert(:assessment, %{
        open_at: Timex.shift(Timex.now(), days: -10),
        close_at: Timex.shift(Timex.now(), days: -5)
      })

    after_close_at_question = insert(:mcq_question, %{assessment: after_close_at_assessment})

    after_close_at_conn = post(conn, build_url(after_close_at_question.id), %{answer: 5})
    assert response(after_close_at_conn, 403) == "Assessment not open"
    assert is_nil(get_answer_value(after_close_at_question, after_close_at_assessment, user))

    unpublished_assessment = insert(:assessment, %{is_published: false})

    unpublished_question = insert(:mcq_question, %{assessment: unpublished_assessment})

    unpublished_conn = post(conn, build_url(unpublished_question.id), %{answer: 5})
    assert response(unpublished_conn, 403) == "Assessment not open"
    assert is_nil(get_answer_value(unpublished_question, unpublished_assessment, user))
  end

  defp build_url(question_id) do
    "/v1/assessments/question/#{question_id}/submit/"
  end

  defp get_answer_value(question, assessment, user) do
    answer =
      Answer
      |> where(question_id: ^question.id)
      |> join(:inner, [a], s in assoc(a, :submission))
      |> where([a, s], s.student_id == ^user.id)
      |> where([a, s], s.assessment_id == ^assessment.id)
      |> Repo.one()

    if answer do
      case question.type do
        :mcq -> Map.get(answer.answer, "choice_id")
        :programming -> Map.get(answer.answer, "code")
      end
    end
  end
end
