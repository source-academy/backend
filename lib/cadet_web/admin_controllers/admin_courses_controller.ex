defmodule CadetWeb.AdminCoursesController do
  use CadetWeb, :controller

  use PhoenixSwagger

  alias Cadet.Courses

  def update_course_config(conn, params = %{"courseid" => course_id}) when is_ecto_id(course_id) do
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

  swagger_path :update_course_config do
    put("/admin/courses/{courseId}/course_config")

    summary("Updates the course configuration for the specified course")

    security([%{JWT: []}])

    consumes("application/json")

    parameters do
      courseId(:path, :integer, "Course ID", required: true)
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

    # :TODO Check if this Forbidden comes from ensure_role. How about EnsureAuthenticated?
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
