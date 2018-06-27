defmodule CadetWeb.AnswerController do
  use CadetWeb, :controller

  use PhoenixSwagger

  alias Cadet.Assessments.Question

  plug(:can_submit, roles: [:student])
  plug(:assign_question)

  def submit(conn, params) do
    # check role
    # get question
    # submit
    # handle error
    IO.puts(inspect(params))
    # IO.puts(get_session(conn, :current_user))

    if conn.assigns.current_user.role == :student do
      IO.puts("true")
    end

    conn
  end

  defp assign_question(conn, _) do
    question = Repo.get(Question, conn.parms.["questionid"])
    IO.puts(inspect(question))

    conn
  end

  defp can_submit(conn, options) do
    IO.puts(inspect(conn))

    if conn.assigns.current_user.role in options[:roles] do
      conn
    else
      conn
      |> send_resp(:unauthorized, "Your role is not authorised to answer questions")
      |> halt()
    end
  end

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
    response(400, "Missing parameter(s) or wrong answer type")
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
