defmodule CadetWeb.VersionsController do
  @moduledoc """
  Handles code versioning and history
  """
  use CadetWeb, :controller
  use PhoenixSwagger
  require Logger

  alias Cadet.Assessments

  def history(conn, %{"questionid" => question_id}) do
    course_reg = conn.assigns[:course_reg]

    Logger.info(
      "Fetching all versions for question #{question_id} for user #{course_reg.id} in course #{course_reg.course_id}"
    )

    with {:question, question} when not is_nil(question) <-
           {:question, Assessments.get_question(question_id)},
         {:ok, versions} <- Assessments.get_versions(question, course_reg) do
      conn
      |> put_status(:ok)
      |> put_resp_content_type("application/json")
      |> render("index.json", versions: versions)
    else
      {:question, nil} ->
        conn
        |> put_status(:not_found)
        |> text("Question not found")

      {:error, {status, message}} ->
        conn
        |> put_status(status)
        |> text(message)

      other ->
        Logger.error("Unexpected error in versions controller: #{inspect(other)}")

        conn
        |> put_status(:internal_server_error)
        |> text("An unexpected error occurred.")
    end
  end

  def save(conn, %{"questionid" => question_id, "content" => content}) do
    course_reg = conn.assigns[:course_reg]

    with {:question, question} when not is_nil(question) <-
           {:question, Assessments.get_question(question_id)},
         {:ok, _nil} <- Assessments.save_version(question, course_reg, content) do
      text(conn, "OK")
    else
      {:question, nil} ->
        conn
        |> put_status(:not_found)
        |> text("Question not found")

      {:error, {status, message}} ->
        conn
        |> put_status(status)
        |> text(message)

      other ->
        Logger.error("Unexpected error in versions controller: #{inspect(other)}")

        conn
        |> put_status(:internal_server_error)
        |> text("An unexpected error occurred.")
    end
  end

  def save(conn, _params) do
    conn
    |> put_status(:bad_request)
    |> text("Missing required parameters.")
  end

  def name(conn, %{
        "questionid" => question_id,
        "versionid" => version_id,
        "name" => name
      }) do
    course_reg = conn.assigns[:course_reg]

    with {:question, question} when not is_nil(question) <-
           {:question, Assessments.get_question(question_id)},
         {:ok, _nil} <- Assessments.name_version(question, course_reg, version_id, name) do
      text(conn, "OK")
    else
      {:question, nil} ->
        conn
        |> put_status(:not_found)
        |> text("Question not found")

      {:error, {status, message}} ->
        conn
        |> put_status(status)
        |> text(message)

      other ->
        Logger.error("Unexpected error in versions controller: #{inspect(other)}")

        conn
        |> put_status(:internal_server_error)
        |> text("An unexpected error occurred.")
    end
  end

  def name(conn, _params) do
    conn
    |> put_status(:bad_request)
    |> text("Missing required parameters.")
  end

  def swagger_definitions do
    %{
      Version:
        swagger_schema do
          properties do
            id(:integer, "Unique identifier", required: true)
            content(:object, "Version of the answer depending on question type", required: true)
            name(:string, "The name of the version")
            restored(:boolean, "Whether this version was restored from a previous version")
            restored_from(:integer, "ID of the version this was restored from")
            answer_id(:integer, "Associated answer ID", required: true)
            inserted_at(:string, "Creation timestamp", format: "date-time")
            updated_at(:string, "Last update timestamp", format: "date-time")
          end
        end,
      VersionSaveRequest:
        swagger_schema do
          properties do
            content(:string_or_integer, "Version of the answer depending on question type",
              required: true
            )
          end
        end
    }
  end

  swagger_path :history do
    get("/assessments/question/{questionId}/version/history")

    summary("Get a list of versions for an answer")

    security([%{JWT: []}])

    produces("application/json")

    parameters do
      questionId(:path, :integer, "question id", required: true)
    end

    response(200, "OK")
    response(400, "Invalid parameters")
    response(404, "Question not found")
  end

  swagger_path :save do
    post("/assessments/question/{questionId}/version/save")

    summary("Submit an answer to a question and save it as a version")

    description(
      "For MCQ, answer contains choice_id. For programming question, this is a string containing the student's code."
    )

    security([%{JWT: []}])

    consumes("application/json")
    produces("application/json")

    parameters do
      questionId(:path, :integer, "question id", required: true)
      content(:body, Schema.ref(:VersionSaveRequest), "answer content", required: true)
    end

    response(200, "OK")
    response(400, "Invalid parameters")
    response(404, "Question not found")
  end

  swagger_path :name do
    put("/assessments/question/{questionId}/version/{versionId}/name")

    summary("Name a version")

    parameters do
      questionId(:path, :integer, "question id", required: true)
      versionId(:path, :integer, "version id", required: true)
      name(:body, :string, "new name", required: true)
    end

    response(200, "OK")
    response(400, "Invalid parameters")
    response(404, "Question or version not found")
  end
end
