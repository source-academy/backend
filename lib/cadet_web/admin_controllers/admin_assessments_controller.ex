defmodule CadetWeb.AdminAssessmentsController do
  use CadetWeb, :controller

  use PhoenixSwagger

  import Ecto.Query, only: [where: 2]
  import Cadet.Updater.XMLParser, only: [parse_xml: 4]

  alias Cadet.{Assessments, Repo}
  alias Cadet.Assessments.Assessment
  alias Cadet.Accounts.CourseRegistration

  def index(conn, %{"course_reg_id" => course_reg_id}) do
    course_reg = Repo.get(CourseRegistration, course_reg_id)
    {:ok, assessments} = Assessments.all_assessments(course_reg)

    render(conn, "index.json", assessments: assessments)
  end

  def get_assessment(conn, %{"course_reg_id" => course_reg_id, "assessmentid" => assessment_id})
      when is_ecto_id(assessment_id) do
    course_reg = Repo.get(CourseRegistration, course_reg_id)

    case Assessments.assessment_with_questions_and_answers(assessment_id, course_reg) do
      {:ok, assessment} -> render(conn, "show.json", assessment: assessment)
      {:error, {status, message}} -> send_resp(conn, status, message)
    end
  end

  def create(conn, %{
        "course_id" => course_id,
        "assessment" => assessment,
        "forceUpdate" => force_update,
        "assessmentConfigId" => assessment_config_id
      }) do
    file =
      assessment["file"].path
      |> File.read!()

    result =
      case force_update do
        "true" -> parse_xml(file, course_id, assessment_config_id, true)
        "false" -> parse_xml(file, course_id, assessment_config_id, false)
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

  def delete(conn, %{"course_id" => course_id, "assessmentid" => assessment_id}) do
    with {:same_course, true} <- {:same_course, is_same_course(course_id, assessment_id)},
         {:ok, _} <- Assessments.delete_assessment(assessment_id) do
      text(conn, "OK")
    else
      {:same_course, false} ->
        conn
        |> put_status(403)
        |> text("User not allow to delete assessments from another course")

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
      if is_nil(is_published) do
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
    if is_nil(open_at) and is_nil(close_at) do
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

  defp is_same_course(course_id, assessment_id) do
    Assessment
    |> where(id: ^assessment_id)
    |> where(course_id: ^course_id)
    |> Repo.exists?()
  end

  swagger_path :index do
    get("/admin/users/{courseRegId}/assessments")

    summary("Fetches assessment overviews of a user")

    security([%{JWT: []}])

    parameters do
      courseRegId(:path, :integer, "Course Reg ID", required: true)
    end

    response(200, "OK", Schema.array(:AssessmentsList))
    response(401, "Unauthorised")
    response(403, "Forbidden")
  end

  swagger_path :create do
    post("/admin/assessments")

    summary("Creates a new assessment or updates an existing assessment")

    security([%{JWT: []}])

    consumes("multipart/form-data")

    parameters do
      assessment(:formData, :file, "Assessment to create or update", required: true)
      forceUpdate(:formData, :boolean, "Force update", required: true)
    end

    response(200, "OK")
    response(400, "XML parse error")
    response(403, "Forbidden")
  end

  swagger_path :delete do
    PhoenixSwagger.Path.delete("/admin/assessments/{assessmentId}")

    summary("Deletes an assessment")

    security([%{JWT: []}])

    parameters do
      assessmentId(:path, :integer, "Assessment ID", required: true)
    end

    response(200, "OK")
    response(403, "Forbidden")
  end

  swagger_path :update do
    post("/admin/assessments/{assessmentId}")

    summary("Updates an assessment")

    security([%{JWT: []}])

    consumes("application/json")

    parameters do
      assessmentId(:path, :integer, "Assessment ID", required: true)

      assessment(:body, Schema.ref(:AdminUpdateAssessmentPayload), "Updated assessment details",
        required: true
      )
    end

    response(200, "OK")
    response(401, "Assessment is already opened")
    response(403, "Forbidden")
  end

  def swagger_definitions do
    %{
      # Schemas for payloads to modify data
      AdminUpdateAssessmentPayload:
        swagger_schema do
          properties do
            closeAt(:string, "Open date", required: false)
            openAt(:string, "Close date", required: false)
            isPublished(:boolean, "Whether the assessment is published", required: false)
          end
        end
    }
  end
end
