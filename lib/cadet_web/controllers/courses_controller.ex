defmodule CadetWeb.CoursesController do
  use CadetWeb, :controller

  use PhoenixSwagger

  alias Cadet.Courses

  def index(conn, %{"course_id" => course_id}) when is_ecto_id(course_id) do
    case Courses.get_course_config(course_id) do
      {:ok, config} -> render(conn, "config.json", config: config)
      {:error, {status, message}} -> send_resp(conn, status, message)
    end
  end

  def create(conn, params) do
    user = conn.assigns.current_user
    params = params |> to_snake_case_atom_keys()

    required_keys = [
      :course_name,
      :course_short_name,
      :viewable,
      :enable_game,
      :enable_achievements,
      :enable_sourcecast,
      :source_chapter,
      :source_variant,
      :module_help_text
    ]

    if Enum.reduce(required_keys, true, fn x, acc -> acc and Map.has_key?(params, x) end) do
      case Courses.create_course_config(params, user) do
        {:ok, _} ->
          text(conn, "OK")

        {:error, _, _, _} ->
          conn
          |> put_status(:bad_request)
          |> text("Invalid parameter(s)")
      end
    else
      send_resp(conn, :bad_request, "Missing parameter(s)")
    end
  end

  swagger_path :create do
    post("/v2/config/create")

    summary("Creates a new course")

    security([%{JWT: []}])
    consumes("application/json")

    parameters do
      course_name(:body, :string, "Course name", required: true)
      course_short_name(:body, :string, "Course module code", required: true)
      viewable(:body, :boolean, "Course viewability", required: true)
      enable_game(:body, :boolean, "Enable game", required: true)
      enable_achievements(:body, :boolean, "Enable achievements", required: true)
      enable_sourcecast(:body, :boolean, "Enable sourcecast", required: true)
      source_chapter(:body, :number, "Default source chapter", required: true)

      source_variant(:body, Schema.ref(:SourceVariant), "Default source variant name",
        required: true
      )

      module_help_text(:body, :string, "Module help text", required: true)
    end
  end

  swagger_path :get_course_config do
    get("/v2/courses/{course_id}/config")

    summary("Retrieves the course configuration of the specified course")

    security([%{JWT: []}])

    produces("application/json")

    parameters do
      course_id(:path, :integer, "Course ID", required: true)
    end

    response(200, "OK", Schema.ref(:Config))
    response(400, "Invalid course_id")
  end

  def swagger_definitions do
    %{
      Config:
        swagger_schema do
          title("Course Configuration")

          properties do
            course_name(:string, "Course name", required: true)
            course_short_name(:string, "Course module code", required: true)
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
            course_name: "Programming Methodology",
            course_short_name: "CS1101S",
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
