defmodule CadetWeb.AdminCoursesController do
  use CadetWeb, :controller

  use PhoenixSwagger

  alias Cadet.Courses

  def update_course_config(conn, params = %{"course_id" => course_id})
      when is_ecto_id(course_id) do
    params = params |> to_snake_case_atom_keys()

    if (Map.has_key?(params, :source_chapter) and Map.has_key?(params, :source_variant)) or
         (not Map.has_key?(params, :source_chapter) and
            not Map.has_key?(params, :source_variant)) do
      case Courses.update_course_config(course_id, params) do
        {:ok, _} ->
          text(conn, "OK")

        {:error, {status, message}} ->
          send_resp(conn, status, message)

        {:error, _} ->
          conn
          |> put_status(:bad_request)
          |> text("Invalid parameter(s)")
      end
    else
      send_resp(conn, :bad_request, "Missing parameter(s)")
    end
  end

  def get_assessment_configs(conn, %{"course_id" => course_id}) when is_ecto_id(course_id) do
    assessment_configs = Courses.get_assessment_configs(course_id)
    render(conn, "assessment_configs.json", %{configs: assessment_configs})
  end

  def update_assessment_configs(conn, %{
        "course_id" => course_id,
        "assessmentConfigs" => assessment_configs
      })
      when is_ecto_id(course_id) and is_list(assessment_configs) do
    if Enum.all?(assessment_configs, &is_map/1) do
      configs = assessment_configs |> Enum.map(&to_snake_case_atom_keys/1)

      case Courses.mass_upsert_and_reorder_assessment_configs(course_id, configs) do
        {:ok, _} ->
          text(conn, "OK")

        {:error, {status, message}} ->
          conn
          |> put_status(status)
          |> text(message)
      end
    else
      send_resp(conn, :bad_request, "List parameter does not contain all maps")
    end
  end

  def update_assessment_configs(conn, _) do
    send_resp(conn, :bad_request, "Missing List parameter(s)")
  end

  def delete_assessment_config(conn, %{
        "course_id" => course_id,
        "assessmentConfig" => assessment_config
      })
      when is_ecto_id(course_id) and is_map(assessment_config) do
      config = assessment_config |> to_snake_case_atom_keys()

      case Courses.delete_assessment_config(course_id, config) do
        {:ok, _} ->
          text(conn, "OK")

        {:error, message} ->
          conn
          |> put_status(:bad_request)
          |> text(message)
      end

  end

  def delete_assessment_config(conn, _) do
    send_resp(conn, :bad_request, "Missing Map parameter(s)")
  end

  swagger_path :update_course_config do
    put("/v2/courses/{course_id}/admin/onfig")

    summary("Updates the course configuration for the specified course")

    security([%{JWT: []}])

    consumes("application/json")

    parameters do
      course_id(:path, :integer, "Course ID", required: true)
      course_name(:body, :string, "Course name")
      course_short_name(:body, :string, "Course module code")
      viewable(:body, :boolean, "Course viewability")
      enable_game(:body, :boolean, "Enable game")
      enable_achievements(:body, :boolean, "Enable achievements")
      enable_sourcecast(:body, :boolean, "Enable sourcecast")
      sublanguage(:body, Schema.ref(:AdminSublanguage), "sublanguage object")
      module_help_text(:body, :string, "Module help text")
    end

    response(200, "OK")
    response(400, "Missing or invalid parameter(s)")
    response(403, "Forbidden")
  end

  swagger_path :update_assessment_configs do
    put("/v2/courses/{course_id}/admin/config/assessment_configs")

    summary("Updates the assessment configuration for the specified course")

    security([%{JWT: []}])

    consumes("application/json")

    parameters do
      course_id(:path, :integer, "Course ID", required: true)
      assessment_configs(:body, :list, "Assessment Configs")
    end

    response(200, "OK")
    response(400, "Missing or invalid parameter(s)")
    response(403, "Forbidden")
  end

  def swagger_definitions do
    %{
      AdminSublanguage:
        swagger_schema do
          title("AdminSublanguage")

          properties do
            chapter(:integer, "Chapter number from 1 to 4", required: true, minimum: 1, maximum: 4)

            variant(Schema.ref(:SourceVariant), "Variant name", required: true)
          end

          example(%{
            chapter: 2,
            variant: "lazy"
          })
        end
    }
  end
end
