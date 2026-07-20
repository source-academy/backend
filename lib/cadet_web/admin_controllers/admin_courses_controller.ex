defmodule CadetWeb.AdminCoursesController do
  use CadetWeb, :controller
  use OpenApiSpex.ControllerSpecs

  plug(OpenApiSpex.Plug.CastAndValidate,
    render_error: CadetWeb.Plugs.OpenApiErrorRenderer,
    replace_params: false
  )

  alias Cadet.Courses
  alias Cadet.Chatbot.CourseDocuments
  alias CadetWeb.ApiSpec.ErrorResponses
  alias CadetWeb.Schemas
  alias OpenApiSpex.Schema

  tags(["Courses"])
  security([%{"JWT" => []}])

  operation(:update_course_config,
    summary: "Update the configuration of the course",
    parameters: [
      course_id: [in: :path, type: :integer, required: true, description: "Course ID"]
    ],
    request_body:
      {"The course configuration to update", "application/json",
       Schemas.UpdateCourseConfigRequest},
    responses: [
      ok: {"Configuration updated", "text/plain", %Schema{type: :string}},
      bad_request: ErrorResponses.bad_request(),
      unauthorized: ErrorResponses.unauthorised(),
      forbidden: ErrorResponses.forbidden()
    ]
  )

  def update_course_config(conn, params = %{"course_id" => course_id})
      when is_ecto_id(course_id) do
    params = params |> to_snake_case_atom_keys()

    case Courses.update_course_config(course_id, params) do
      {:ok, _} ->
        text(conn, "OK")

      # coveralls-ignore-start
      # case of invalid course_id will not happen here
      {:error, {status, message}} ->
        send_resp(conn, status, message)

      # coveralls-ignore-stop

      {:error, _} ->
        conn
        |> put_status(:bad_request)
        |> text("Invalid parameter(s)")
    end
  end

  operation(:get_assessment_configs,
    summary: "Get the assessment configurations of the course",
    parameters: [
      course_id: [in: :path, type: :integer, required: true, description: "Course ID"]
    ],
    responses: [
      ok:
        {"List of assessment configurations", "application/json",
         %Schema{type: :array, items: Schemas.AssessmentConfiguration}},
      unauthorized: ErrorResponses.unauthorised(),
      forbidden: ErrorResponses.forbidden()
    ]
  )

  def get_assessment_configs(conn, %{"course_id" => course_id}) when is_ecto_id(course_id) do
    assessment_configs = Courses.get_assessment_configs(course_id)
    render(conn, "assessment_configs.json", %{configs: assessment_configs})
  end

  operation(:update_assessment_configs,
    summary: "Replace the assessment configurations of the course",
    parameters: [
      course_id: [in: :path, type: :integer, required: true, description: "Course ID"]
    ],
    request_body:
      {"The assessment configurations", "application/json",
       Schemas.UpdateAssessmentConfigsRequest},
    responses: [
      ok: {"Configurations updated", "text/plain", %Schema{type: :string}},
      bad_request: ErrorResponses.bad_request(),
      unauthorized: ErrorResponses.unauthorised(),
      forbidden: ErrorResponses.forbidden()
    ]
  )

  def update_assessment_configs(conn, %{
        "course_id" => course_id,
        "assessmentConfigs" => assessment_configs
      })
      when is_ecto_id(course_id) and is_list(assessment_configs) do
    if Enum.all?(assessment_configs, &is_map/1) do
      # coveralls-ignore-start
      configs =
        assessment_configs
        |> Enum.map(&to_snake_case_atom_keys/1)
        |> update_in(
          [Access.all()],
          &with(
            {v, m} <- Map.pop(&1, :display_in_dashboard),
            do: Map.put(m, :show_grading_summary, v)
          )
        )

      # coveralls-ignore-stop

      case Courses.mass_upsert_and_reorder_assessment_configs(course_id, configs) do
        {:ok, _} ->
          text(conn, "OK")

        {:error, {status, message}} ->
          conn
          |> put_status(status)
          |> text(message)
      end
    else
      send_resp(
        conn,
        :bad_request,
        "assessmentConfigs should be a list of assessment configuration objects"
      )
    end
  end

  def update_assessment_configs(conn, _) do
    send_resp(conn, :bad_request, "missing assessmentConfig")
  end

  operation(:delete_assessment_config,
    summary: "Delete an assessment configuration from the course",
    parameters: [
      course_id: [in: :path, type: :integer, required: true, description: "Course ID"],
      assessment_config_id: [
        in: :path,
        type: :integer,
        required: true,
        description: "Assessment config ID"
      ]
    ],
    responses: [
      ok: {"Configuration deleted", "text/plain", %Schema{type: :string}},
      bad_request: ErrorResponses.bad_request(),
      unauthorized: ErrorResponses.unauthorised(),
      forbidden: ErrorResponses.forbidden()
    ]
  )

  def delete_assessment_config(conn, %{
        "course_id" => course_id,
        "assessment_config_id" => assessment_config_id
      })
      when is_ecto_id(course_id) and is_ecto_id(assessment_config_id) do
    case Courses.delete_assessment_config(course_id, assessment_config_id) do
      {:ok, _} ->
        text(conn, "OK")

      {:error, message} ->
        conn
        |> put_status(:bad_request)
        |> text(message)
    end
  end

  operation(:get_document_map,
    summary: "Get the Pixelbot document map for the course",
    parameters: [
      course_id: [in: :path, type: :integer, required: true, description: "Course ID"]
    ],
    responses: [
      ok: {"The document map", "application/json", Schemas.DocumentMapResponse},
      unauthorized: ErrorResponses.unauthorised(),
      forbidden: ErrorResponses.forbidden()
    ]
  )

  def get_document_map(conn, _params) do
    document_map = CourseDocuments.build_document_map_json()
    json(conn, %{documentMap: document_map})
  end
end
