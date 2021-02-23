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

  def update(conn, params = %{"assessmentid" => assessment_id}) when is_ecto_id(assessment_id) do
    open_at = params |> Map.get("openAt")
    close_at = params |> Map.get("closeAt")
    is_published = params |> Map.get("isPublished")

    updated_assessment =
      if is_published == nil do
        %{}
      else
        %{:is_published => is_published}
      end

    with {:ok, assessment} <- check_dates(open_at, close_at, updated_assessment),
         {:ok, _nil} <- Assessments.update_assessment(assessment_id, assessment) do
      text(conn, "OK")
    else
      {:error, {status, message}} ->
        conn
        |> put_status(status)
        |> text(message)
    end
  end

  defp check_dates(open_at, close_at, assessment) do
    if open_at == nil and close_at == nil do
      {:ok, assessment}
    else
      formatted_open_date = elem(DateTime.from_iso8601(open_at), 1)
      formatted_close_date = elem(DateTime.from_iso8601(close_at), 1)

      if Timex.before?(formatted_close_date, formatted_open_date) do
        {:error, {:bad_request, "New end date should occur after new opening date"}}
      else
        assessment = Map.put(assessment, :open_at, formatted_open_date)
        assessment = Map.put(assessment, :close_at, formatted_close_date)

        {:ok, assessment}
      end
    end
  end

  swagger_path :create do
    post("/admin/assessments")

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
    PhoenixSwagger.Path.delete("/admin/assessments/:assessmentid")

    summary("Deletes an assessment.")

    security([%{JWT: []}])

    parameters do
      assessmentId(:path, :integer, "Assessment ID", required: true)
    end

    response(200, "OK")
    response(403, "Forbidden")
  end

  swagger_path :update do
    post("/admin/assessments/:assessmentid")

    summary("Updates an assessment.")

    security([%{JWT: []}])

    consumes("application/json")

    parameters do
      assessmentId(:path, :integer, "Assessment ID", required: true)
      closeAt(:body, :string, "Open date", required: false)
      openAt(:body, :string, "Close date", required: false)
      isPublished(:body, :boolean, "Whether the assessment is published", required: false)
    end

    response(200, "OK")
    response(401, "Assessment is already opened")
    response(403, "Forbidden")
  end
end
