defmodule CadetWeb.AdminAssessmentsController do
  use CadetWeb, :controller

  use PhoenixSwagger

  alias Cadet.Assessments
  import Cadet.Updater.XMLParser, only: [parse_xml: 2]

  def create(conn, %{"assessment" => assessment, "forceUpdate" => force_update}) do
    file =
      assessment["file"].path
      |> File.read!()

    result =
      case force_update do
        "true" -> parse_xml(file, true)
        "false" -> parse_xml(file, false)
      end

    case result do
      :ok ->
        if force_update == "true" do
          text(conn, "Force update OK")
        else
          text(conn, "OK")
        end

      {:ok, warning_message} ->
        text(conn, warning_message)

      {:error, {status, message}} ->
        conn
        |> put_status(status)
        |> text(message)
    end
  end

  def delete(conn, %{"assessmentid" => assessment_id}) do
    result = Assessments.delete_assessment(assessment_id)

    case result do
      {:ok, _nil} ->
        text(conn, "OK")

      {:error, {status, message}} ->
        conn
        |> put_status(status)
        |> text(message)
    end
  end

  def publish(conn, %{"assessmentid" => assessment_id}) do
    result = Assessments.toggle_publish_assessment(assessment_id)

    case result do
      {:ok, _nil} ->
        text(conn, "OK")

      {:error, {status, message}} ->
        conn
        |> put_status(status)
        |> text(message)
    end
  end

  def update(conn, %{"assessmentid" => assessment_id, "closeAt" => close_at, "openAt" => open_at}) do
    formatted_close_date = elem(DateTime.from_iso8601(close_at), 1)
    formatted_open_date = elem(DateTime.from_iso8601(open_at), 1)

    result =
      Assessments.change_dates_assessment(
        assessment_id,
        formatted_close_date,
        formatted_open_date
      )

    case result do
      {:ok, _nil} ->
        text(conn, "OK")

      {:error, {status, message}} ->
        conn
        |> put_status(status)
        |> text(message)
    end
  end

  swagger_path :create do
    post("/assessments")

    summary("Creates a new assessment or updates an existing assessment.")

    security([%{JWT: []}])

    consumes("application/json")

    parameters do
      assessment(:body, :file, "Assessment to create or update", required: true)
      forceUpdate(:body, :boolean, "Force update", required: true)
    end

    response(200, "OK")
    response(400, "XML parse error")
    response(403, "Forbidden")
  end

  swagger_path :delete do
    PhoenixSwagger.Path.delete("/assessments/:assessmentid")

    summary("Deletes an assessment.")

    security([%{JWT: []}])

    parameters do
      assessmentId(:path, :integer, "Assessment ID", required: true)
    end

    response(200, "OK")
    response(403, "Forbidden")
  end

  swagger_path :publish do
    post("/assessments/publish/:assessmentid")

    summary("Toggles an assessment between published and unpublished")

    security([%{JWT: []}])

    parameters do
      assessmentId(:path, :integer, "assessment id", required: true)
    end

    response(200, "OK")
    response(403, "Forbidden")
  end

  swagger_path :update do
    post("/assessments/update/:assessmentid")

    summary("Changes the open/close date of an assessment")

    security([%{JWT: []}])

    consumes("application/json")

    parameters do
      assessmentId(:path, :integer, "assessment id", required: true)
      closeAt(:body, :string, "open date", required: true)
      openAt(:body, :string, "close date", required: true)
    end

    response(200, "OK")
    response(401, "Assessment is already opened")
    response(403, "Forbidden")
  end
end
