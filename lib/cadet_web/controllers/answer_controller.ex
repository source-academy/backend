defmodule CadetWeb.AnswerController do
  use CadetWeb, :controller
  use OpenApiSpex.ControllerSpecs

  plug(OpenApiSpex.Plug.CastAndValidate,
    render_error: CadetWeb.Plugs.OpenApiErrorRenderer,
    replace_params: false
  )

  alias Cadet.Assessments
  alias CadetWeb.ApiSpec.ErrorResponses
  alias CadetWeb.Schemas

  tags(["Assessments"])
  security([%{"JWT" => []}])

  # These roles can save and finalise answers for
  # closed assessments and submitted answers
  @bypass_closed_roles ~w(staff admin)a

  operation(:submit,
    summary: "Submit an answer to a question",
    parameters: [
      course_id: [in: :path, type: :integer, required: true, description: "Course ID"],
      questionid: [in: :path, type: :integer, required: true, description: "Question ID"]
    ],
    request_body: {"The answer", "application/json", Schemas.SubmitAnswerRequest},
    responses: [
      ok: {"Answer submitted", "text/plain", %OpenApiSpex.Schema{type: :string}},
      bad_request: ErrorResponses.bad_request(),
      unauthorized: ErrorResponses.unauthorised(),
      forbidden: ErrorResponses.forbidden(),
      not_found: ErrorResponses.not_found()
    ]
  )

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

  operation(:check_last_modified,
    summary: "Check whether the stored answer is newer than the client's copy",
    parameters: [
      course_id: [in: :path, type: :integer, required: true, description: "Course ID"],
      questionid: [in: :path, type: :integer, required: true, description: "Question ID"]
    ],
    request_body:
      {"The client's last-known modification time", "application/json",
       Schemas.CheckLastModifiedRequest},
    responses: [
      ok: {"Comparison result", "application/json", Schemas.LastModifiedResponse},
      unauthorized: ErrorResponses.unauthorised(),
      forbidden: ErrorResponses.forbidden(),
      not_found: ErrorResponses.not_found()
    ]
  )

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
end
