defmodule CadetWeb.AnswerController do
  use CadetWeb, :controller

  use PhoenixSwagger

  alias Cadet.Assessments

  def submit(conn, %{"questionid" => question_id, "answer" => answer}) do
    # offload to Cadet.Assessments:
    # check role
    # get question
    # check deadline
    # check format
    # submit
    # handle error
    IO.puts(inspect(conn))
    Assessments.answer_question(question_id, conn.assigns.current_user, answer)
    # IO.puts(get_session(conn, :current_user))

    if conn.assigns.current_user.role == :student do
      IO.puts("true")
    end

    conn
  end

  def submit(conn, _parms) do
    send_resp(conn, :bad_request, "Missing parameter(s)")
  end

  # defp check_deadline_not_past(conn, _) do
  #   if Question.can_submit?(conn.assigns.question) do
  #     conn
  #   else
  #     conn
  #     |> send_resp(:unauthorised, "Deadline past")
  #     |> halt()
  #   end
  # end

  # defp assign_question(conn, _) do
  #   question = Repo.get(Question, conn.params["questionid"])

  #   if question && question.can_submit?() do
  #     conn
  #   else
  #     conn
  #     |> send_resp(:bad_request, "Invalid question")
  #     |> halt()
  #   end
  # end

  swagger_path :submit do
    post("/assessments/question/{questionId}/submit")

    summary("Submit an answer to a question.")

    description(
      "For MCQ, answer contains choice_id. For programming question, this is a string containing the student's code."
    )

    security([%{JWT: []}])

    consumes("application/json")

    parameters do
      questionId(:path, :integer, "question id", required: true)
      answer(:body, Schema.ref(:Answer), "answer", required: true)
    end

    response(200, "OK")
    response(400, "Invalid parameters")
    response(401, "Unauthorised")
  end

  def swagger_definitions do
    %{
      Answer:
        swagger_schema do
          properties do
            answer(
              :string_or_int,
              "answer of appropriate type depending on question type",
              required: true
            )
          end
        end
    }
  end
end
