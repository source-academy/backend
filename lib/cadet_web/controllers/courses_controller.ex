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
        if conn.assigns.course_reg.role == :admin do
          render(conn, "config_admin.json", config: config)
        else
          render(conn, "config.json", config: config)
        end

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

  defp check_resume_code(course_id, resume_code) do
    case Courses.get_course_config(course_id) do
      {:ok, config} -> {:ok, config.resume_code == resume_code}
      {:error, {status_code, message}} -> {:error, {status_code, message}}
    end
  end

  defp unpause_user(conn, user) do
    update_result =
      user
      |> Cadet.Accounts.User.changeset(%{is_paused: false})
      |> Cadet.Repo.update()

    case update_result do
      {:ok, _} -> conn |> send_resp(:ok, "")
      {:error, _} -> conn |> send_resp(500, "")
    end
  end

  def try_unpause_user(conn, %{"course_id" => course_id}) when is_ecto_id(course_id) do
    user = conn.assigns.current_user
    resume_code = Map.get(conn.body_params, "resume_code", nil)

    case check_resume_code(course_id, resume_code) do
      {:ok, true} -> unpause_user(conn, user)
      {:ok, false} -> conn |> send_resp(:forbidden, "")
      {:error, {status_code, message}} -> conn |> send_resp(status_code, message)
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
      enable_exam_mode(:body, :boolean, "Enable exam mode", required: true)
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
            enable_exam_mode(:boolean, "Enable exam mode", required: true)
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
