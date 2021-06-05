defmodule CadetWeb.CoursesController do
  use CadetWeb, :controller

  use PhoenixSwagger

  alias Cadet.Courses

  def index(conn, %{"courseid" => course_id}) when is_ecto_id(course_id) do
    case Courses.get_course_config(course_id) do
      {:ok, config} -> render(conn, "config.json", config: config)
      {:error, {status, message}} -> send_resp(conn, status, message)
    end
  end

  swagger_path :get_course_config do
    get("/courses/{courseId}/config")

    summary("Retrieves the course configuration of the specified course")

    security([%{JWT: []}])

    produces("application/json")

    parameters do
      courseId(:path, :integer, "Course ID", required: true)
    end

    response(200, "OK", Schema.ref(:Config))
    response(400, "Invalid courseId")
  end

  def swagger_definitions do
    %{
      Config:
        swagger_schema do
          title("Course Configuration")

          properties do
            name(:string, "Course name", required: true)
            module_code(:string, "Course module code", required: true)
            viewable(:boolean, "Course viewability", required: true)
            enable_game(:boolean, "Enable game", required: true)
            enable_achievements(:boolean, "Enable achievements", required: true)
            enable_sourcecast(:boolean, "Enable sourcecast", required: true)
            source_chapter(:integer, "Source Chapter number from 1 to 4", required: true)
            source_variant(Schema.ref(:SourceVariant), "Source Variant name", required: true)
            module_help_text(:string, "Module help text", required: true)
            assessment_types(:list, "Assessment Types", required: true)
          end

          example(%{
            name: "Programming Methodology",
            module_code: "CS1101S",
            viewable: true,
            enable_game: true,
            enable_achievements: true,
            enable_sourcecast: true,
            source_chapter: 1,
            source_variant: "default",
            module_help_text: "Help text",
            assessment_types: ["Missions", "Quests", "Paths", "Contests", "Others"]
          })
        end,
      SourceVariant:
        swagger_schema do
          type(:string)
          enum([:default, :concurrent, :gpu, :lazy, "non-det", :wasm])
        end
    }
  end
end
