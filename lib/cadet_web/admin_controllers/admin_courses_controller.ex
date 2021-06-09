defmodule CadetWeb.AdminCoursesController do
  use CadetWeb, :controller

  use PhoenixSwagger

  alias Cadet.Courses

  def update_course_config(conn, params = %{"course_id" => course_id})
      when is_ecto_id(course_id) do
    params = for {key, val} <- params, into: %{}, do: {String.to_atom(key), val}

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

  def update_assessment_config(conn, %{
        "course_id" => course_id,
        "early_submission_xp" => early_xp,
        "hours_before_early_xp_decay" => hours_before_decay,
        "decay_rate_points_per_hour" => decay_rate
      })
      when is_ecto_id(course_id) do
    case Courses.update_assessment_config(course_id, early_xp, hours_before_decay, decay_rate) do
      {:ok, _} ->
        text(conn, "OK")

      {:error, _} ->
        conn
        |> put_status(:bad_request)
        |> text("Invalid parameter(s)")
    end
  end

  def update_assessment_config(conn, _) do
    send_resp(conn, :bad_request, "Missing parameter(s)")
  end

  def update_assessment_types(conn, %{
        "course_id" => course_id,
        "assessment_types" => assessment_types
      })
      when is_ecto_id(course_id) do
    case Courses.update_assessment_types(course_id, assessment_types) do
      :ok ->
        text(conn, "OK")

      {:error, {status, message}} ->
        conn
        |> put_status(status)
        |> text(message)
    end
  end

  def update_assessment_types(conn, _) do
    send_resp(conn, :bad_request, "Missing parameter(s)")
  end

  swagger_path :update_course_config do
    put("/v2/course/{course_id}/admin/course_config")

    summary("Updates the course configuration for the specified course")

    security([%{JWT: []}])

    consumes("application/json")

    parameters do
      course_id(:path, :integer, "Course ID", required: true)
      name(:body, :string, "Course name")
      module_code(:body, :string, "Course module code")
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

  swagger_path :update_assessment_config do
    put("/v2/course/{course_id}/admin/assessment_config")

    summary("Updates the assessment configuration for the specified course")

    security([%{JWT: []}])

    consumes("application/json")

    parameters do
      course_id(:path, :integer, "Course ID", required: true)
      early_submission_xp(:body, :integer, "Early submission xp")
      hours_before_early_xp_decay(:body, :integer, "Hours before early submission xp decay")
      decay_rate_points_per_hour(:body, :integer, "Decay rate in points per hour")
    end

    response(200, "OK")
    response(400, "Missing or invalid parameter(s)")
    response(403, "Forbidden")
  end

  swagger_path :update_assessment_types do
    put("/admin/courses/{course_id}/assessment_types")

    summary("Updates the assessment types for the specified course")

    security([%{JWT: []}])

    consumes("application/json")

    parameters do
      course_id(:path, :integer, "Course ID", required: true)
      assessment_types(:body, :list, "Assessment Types")
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
