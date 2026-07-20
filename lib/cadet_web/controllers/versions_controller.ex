defmodule CadetWeb.VersionsController do
  @moduledoc """
  Handles code versioning and history
  """
  use CadetWeb, :controller
  use OpenApiSpex.ControllerSpecs

  plug(OpenApiSpex.Plug.CastAndValidate,
    render_error: CadetWeb.Plugs.OpenApiErrorRenderer,
    replace_params: false
  )

  require Logger

  alias Cadet.Assessments
  alias Cadet.Assessments.VersionManager
  alias CadetWeb.ApiSpec.ErrorResponses
  alias CadetWeb.Schemas
  alias OpenApiSpex.Schema

  tags(["Assessments"])
  security([%{"JWT" => []}])

  operation(:index,
    summary: "Get the version history overview for a question's answer",
    parameters: [
      course_id: [in: :path, type: :integer, required: true, description: "Course ID"],
      questionid: [in: :path, type: :integer, required: true, description: "Question ID"]
    ],
    responses: [
      ok:
        {"List of version overviews", "application/json",
         %Schema{type: :array, items: Schemas.VersionOverview}},
      unauthorized: ErrorResponses.unauthorised(),
      forbidden: ErrorResponses.forbidden(),
      not_found: ErrorResponses.not_found(),
      internal_server_error: ErrorResponses.internal_server_error()
    ]
  )

  def index(conn, %{"questionid" => question_id}) do
    course_reg = conn.assigns[:course_reg]

    Logger.info(
      "Fetching all versions for question #{question_id} for user #{course_reg.id} in course #{course_reg.course_id}"
    )

    with {:question, question} when not is_nil(question) <-
           {:question, Assessments.get_question(question_id)},
         {:ok, versions} <- VersionManager.get_versions(question, course_reg) do
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

  operation(:show,
    summary: "Get the content of a specific answer version",
    parameters: [
      course_id: [in: :path, type: :integer, required: true, description: "Course ID"],
      questionid: [in: :path, type: :integer, required: true, description: "Question ID"],
      versionid: [in: :path, type: :integer, required: true, description: "Version ID"]
    ],
    responses: [
      ok: {"Version content", "application/json", Schemas.Version},
      unauthorized: ErrorResponses.unauthorised(),
      forbidden: ErrorResponses.forbidden(),
      not_found: ErrorResponses.not_found(),
      internal_server_error: ErrorResponses.internal_server_error()
    ]
  )

  def show(conn, %{"questionid" => question_id, "versionid" => version_id}) do
    course_reg = conn.assigns[:course_reg]

    with {:question, question} when not is_nil(question) <-
           {:question, Assessments.get_question(question_id)},
         {:ok, version} <- VersionManager.get_version(question, course_reg, version_id) do
      conn
      |> put_status(:ok)
      |> put_resp_content_type("application/json")
      |> render("show.json", version: version)
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

  operation(:save,
    summary: "Save the current answer as a new version",
    parameters: [
      course_id: [in: :path, type: :integer, required: true, description: "Course ID"],
      questionid: [in: :path, type: :integer, required: true, description: "Question ID"]
    ],
    request_body: {"The answer content", "application/json", Schemas.SaveVersionRequest},
    responses: [
      ok: {"Version saved", "text/plain", %Schema{type: :string}},
      bad_request: ErrorResponses.bad_request(),
      unauthorized: ErrorResponses.unauthorised(),
      forbidden: ErrorResponses.forbidden(),
      not_found: ErrorResponses.not_found(),
      internal_server_error: ErrorResponses.internal_server_error()
    ]
  )

  def save(conn, %{"questionid" => question_id, "content" => content}) do
    course_reg = conn.assigns[:course_reg]

    with {:question, question} when not is_nil(question) <-
           {:question, Assessments.get_question(question_id)},
         {:ok, _nil} <- VersionManager.save_version(question, course_reg, content) do
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

  operation(:name,
    summary: "Name a version",
    parameters: [
      course_id: [in: :path, type: :integer, required: true, description: "Course ID"],
      questionid: [in: :path, type: :integer, required: true, description: "Question ID"],
      versionid: [in: :path, type: :integer, required: true, description: "Version ID"]
    ],
    request_body: {"The new version name", "application/json", Schemas.NameVersionRequest},
    responses: [
      ok: {"Version named", "text/plain", %Schema{type: :string}},
      bad_request: ErrorResponses.bad_request(),
      unauthorized: ErrorResponses.unauthorised(),
      forbidden: ErrorResponses.forbidden(),
      not_found: ErrorResponses.not_found(),
      internal_server_error: ErrorResponses.internal_server_error()
    ]
  )

  def name(conn, %{
        "questionid" => question_id,
        "versionid" => version_id,
        "name" => name
      }) do
    course_reg = conn.assigns[:course_reg]

    with {:question, question} when not is_nil(question) <-
           {:question, Assessments.get_question(question_id)},
         {:ok, _nil} <- VersionManager.name_version(question, course_reg, version_id, name) do
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
end
