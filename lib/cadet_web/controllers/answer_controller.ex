defmodule CadetWeb.AnswerController do
  use CadetWeb, :controller

  use PhoenixSwagger

  alias Cadet.Assessments

  # These roles can save and finalise answers for
  # closed assessments and submitted answers
  @bypass_closed_roles ~w(staff admin)a

  def submit(conn, %{"questionid" => question_id, "answer" => answer})
      when is_ecto_id(question_id) do
    course_reg = conn.assigns[:course_reg]
    can_bypass? = course_reg.role in @bypass_closed_roles

    with {:question, question} when not is_nil(question) <-
           {:question, Assessments.get_question(question_id)},
         {:is_open?, true} <-
           {:is_open?, can_bypass? or Assessments.is_open?(question.assessment)},
         {:ok, _nil} <- Assessments.answer_question(question, course_reg, answer, can_bypass?) do
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

  def check_last_modified(conn, %{
        "questionid" => question_id,
        "lastModifiedAt" => last_modified_at
      })
      when is_ecto_id(question_id) do
    course_reg = conn.assigns[:course_reg]
    can_bypass? = course_reg.role in @bypass_closed_roles

    with {:question, question} when not is_nil(question) <-
           {:question, Assessments.get_question(question_id)},
         {:is_open?, true} <-
           {:is_open?, can_bypass? or Assessments.is_open?(question.assessment)},
         {:ok, last_modified} <-
           Assessments.has_last_modified_answer?(
             question,
             course_reg,
             last_modified_at,
             can_bypass?
           ) do
      conn
      |> put_status(:ok)
      |> put_resp_content_type("application/json")
      |> render("lastModified.json", lastModified: last_modified)
    else
      {:question, nil} ->
        conn
        |> put_status(:not_found)
        |> text("Question not found")

      {:is_open?, false} ->
        conn
        |> put_status(:forbidden)
        |> text("Assessment not open")

      {:error, _} ->
        conn
        |> put_status(:forbidden)
        |> text("Forbidden")
    end
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
