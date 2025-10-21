defmodule CadetWeb.AdminCoursesController do
  use CadetWeb, :controller

  use PhoenixSwagger

  alias Cadet.Courses

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

  swagger_path :update_course_config do
    put("/courses/{course_id}/admin/config")

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
      enable_overall_leaderboard(:body, :boolean, "Enable overall leaderboard")
      enable_contest_leaderboard(:body, :boolean, "Enable contest leaderboard")
      top_leaderboard_display(:body, :integer, "Top Leaderboard Display")
      top_contest_leaderboard_display(:body, :integer, "Top Contest Leaderboard Display")
      enable_sourcecast(:body, :boolean, "Enable sourcecast")
      enable_stories(:body, :boolean, "Enable stories")
      enable_llm_grading(:body, :boolean, "Enable LLM grading")
      llm_api_key(:body, :string, "OpenAI API key for this course")
      sublanguage(:body, Schema.ref(:AdminSublanguage), "sublanguage object")
      module_help_text(:body, :string, "Module help text")
    end

    response(200, "OK")
    response(400, "Missing or invalid parameter(s)")
    response(403, "Forbidden")
  end

  swagger_path :update_assessment_configs do
    put("/courses/{course_id}/admin/config/assessment_configs")

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
            chapter(:integer, "Chapter number from 1 to 4",
              required: true,
              minimum: 1,
              maximum: 4
            )

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
