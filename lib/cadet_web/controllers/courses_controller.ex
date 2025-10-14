defmodule CadetWeb.CoursesController do
  use CadetWeb, :controller

  use PhoenixSwagger
  require Logger

  alias Cadet.Courses
  alias Cadet.Accounts.CourseRegistrations

  def index(conn, %{"course_id" => course_id}) when is_ecto_id(course_id) do
    user = conn.assigns.current_user
    Logger.info("Fetching course configuration for user #{user.id} and course #{course_id}")

    case Courses.get_course_config(course_id) do
      {:ok, config} ->
        Logger.info(
          "Successfully retrieved course configuration for user #{user.id} and course #{course_id}."
        )

        render(conn, "config.json", config: config)

      # coveralls-ignore-start
      # no course error will not happen here
      {:error, {status, message}} ->
        Logger.error(
          "Failed to fetch course configuration for user #{user.id} and course #{course_id}. Status: #{status}."
        )

        send_resp(conn, status, message)
        # coveralls-ignore-stop
    end
  end

  def create(conn, params) do
    user = conn.assigns.current_user
    Logger.info("Creating a new course for user #{user.id}. Super admin: #{user.super_admin}.")

    params = params |> to_snake_case_atom_keys()

    if user.super_admin or CourseRegistrations.get_admin_courses_count(user) < 5 do
      case Courses.create_course_config(params, user) do
        {:ok, course} ->
          Logger.info("Successfully created course #{course.id} for user #{user.id}.")
          text(conn, "OK")

        {:error, _, _, _} ->
          Logger.error("Invalid parameters provided by user #{user.id} while creating a course.")

          conn
          |> put_status(:bad_request)
          |> text("Invalid parameter(s)")
      end
    else
      Logger.error("User #{user.id} has exceeded the limit of 5 admin courses.")

      conn
      |> put_status(:forbidden)
      |> text("User not allowed to be admin of more than 5 courses.")
    end
  end

  swagger_path :create do
    post("/config/create")

    summary("Creates a new course")

    security([%{JWT: []}])
    consumes("application/json")

    parameters do
      course_name(:body, :string, "Course name", required: true)
      course_short_name(:body, :string, "Course module code", required: true)
      viewable(:body, :boolean, "Course viewability", required: true)
      enable_game(:body, :boolean, "Enable game", required: true)
      enable_achievements(:body, :boolean, "Enable achievements", required: true)
      enable_overall_leaderboard(:body, :boolean, "Enable overall leaderboard", required: true)
      enable_contest_leaderboard(:body, :boolean, "Enable contest leaderboard", required: true)
      top_leaderboard_display(:body, :number, "Top leaderboard display", required: true)

      top_contest_leaderboard_display(:body, :number, "Top contest leaderboard display",
        required: true
      )

      enable_sourcecast(:body, :boolean, "Enable sourcecast", required: true)
      enable_stories(:body, :boolean, "Enable stories", required: true)
      enable_llm_grading(:body, :boolean, "Enable LLM grading", required: false)
      llm_api_key(:body, :string, "OpenAI API key for this course", required: false)
      llm_model(:body, :string, "LLM model to be used for this course", required: false)
      llm_api_url(:body, :string, "LLM API URL to be used for this course", required: false)

      llm_course_level_prompt(
        :body,
        :string,
        "LLM course level prompt to be used for this course",
        required: false
      )

      source_chapter(:body, :number, "Default source chapter", required: true)

      source_variant(:body, Schema.ref(:SourceVariant), "Default source variant name",
        required: true
      )

      module_help_text(:body, :string, "Module help text", required: true)
    end
  end

  swagger_path :index do
    get("/courses/{course_id}/config")

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
            enable_overall_leaderboard(:boolean, "Enable overall leaderboard", required: true)
            enable_contest_leaderboard(:boolean, "Enable contest leaderboard", required: true)
            top_leaderboard_display(:boolean, "Top leaderboard display", required: true)

            top_contest_leaderboard_display(:boolean, "Top contest leaderboard display",
              required: true
            )

            enable_sourcecast(:boolean, "Enable sourcecast", required: true)
            enable_stories(:boolean, "Enable stories", required: true)
            enable_llm_grading(:boolean, "Enable LLM grading", required: false)
            llm_api_key(:string, "OpenAI API key for this course", required: false)
            llm_model(:string, "LLM model to be used for this course", required: false)
            llm_api_url(:string, "LLM API URL to be used for this course", required: false)

            llm_course_level_prompt(:string, "LLM course level prompt to be used for this course",
              required: false
            )

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
            enable_overall_leaderboard: true,
            enable_contest_leaderboard: true,
            top_leaderboard_display: 100,
            top_contest_leaderboard_display: 10,
            enable_sourcecast: true,
            enable_stories: false,
            enable_llm_grading: false,
            llm_api_key: "sk-1234567890",
            llm_model: "gpt-4",
            llm_api_url: "https://api.openai.com/v1/chat/completions",
            llm_course_level_prompt:
              "You are a helpful teaching assistant for an introductory programming course",
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
