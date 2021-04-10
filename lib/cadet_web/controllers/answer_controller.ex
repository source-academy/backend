defmodule CadetWeb.AnswerController do
  use CadetWeb, :controller

  use PhoenixSwagger

  alias Cadet.Assessments

  # These roles can save and finalise answers for closed assessments and
  # submitted answers
  @bypass_closed_roles ~w(staff admin)a

  def submit(conn, %{"questionid" => question_id, "answer" => answer})
      when is_ecto_id(question_id) do
    user = conn.assigns[:current_user]
    can_bypass? = user.role in @bypass_closed_roles

    with {:question, question} when not is_nil(question) <-
           {:question, Assessments.get_question(question_id)},
         {:is_open?, true} <-
           {:is_open?, can_bypass? or Assessments.is_open?(question.assessment)},
         {:ok, _nil} <- Assessments.answer_question(question, user, answer, can_bypass?) do
      text(conn, "OK")
    else
      {:question, nil} ->
        conn
        |> put_status(:not_found)
        |> text("Question not found")

      {:is_open?, false} ->
        conn
        |> put_status(:forbidden)
        |> text("Assessment not open")

      {:error, {status, message}} ->
        conn
        |> put_status(status)
        |> text(message)
    end
  end

  def submit(conn, _params) do
    send_resp(conn, :bad_request, "Missing or invalid parameter(s)")
  end

  swagger_path :submit do
    post("/assessments/question/{questionId}/answer")

    summary("Submit an answer to a question")

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
    response(403, "User not permitted to answer questions or assessment not open")
    response(404, "Question not found")
  end

  def swagger_definitions do
    %{
      Answer:
        swagger_schema do
          properties do
            answer(
              # Note: this is technically an invalid type in Swagger/OpenAPI 2.0,
              # but represents that a string or integer could be returned.
              :string_or_integer,
              "answer of appropriate type depending on question type",
              required: true
            )
          end
        end
    }
  end
end
