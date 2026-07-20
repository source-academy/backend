defmodule CadetWeb.CoursesController do
  use CadetWeb, :controller
  use OpenApiSpex.ControllerSpecs

  plug(OpenApiSpex.Plug.CastAndValidate,
    render_error: CadetWeb.Plugs.OpenApiErrorRenderer,
    replace_params: false
  )

  require Logger

  alias Cadet.Courses
  alias Cadet.Accounts.CourseRegistrations
  alias CadetWeb.ApiSpec.ErrorResponses
  alias CadetWeb.Schemas

  tags(["Courses"])
  security([%{"JWT" => []}])

  operation(:index,
    summary: "Get the configuration of the specified course",
    parameters: [
      course_id: [in: :path, type: :integer, required: true, description: "Course ID"]
    ],
    responses: [
      ok: {"Course configuration", "application/json", Schemas.CourseConfigResponse},
      bad_request: ErrorResponses.bad_request(),
      unauthorized: ErrorResponses.unauthorised(),
      forbidden: ErrorResponses.forbidden()
    ]
  )

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

  operation(:create,
    summary: "Create a new course (with the current user as admin)",
    request_body: {"The course configuration", "application/json", Schemas.CreateCourseRequest},
    responses: [
      ok: {"Course created", "text/plain", %OpenApiSpex.Schema{type: :string}},
      bad_request: ErrorResponses.bad_request(),
      unauthorized: ErrorResponses.unauthorised(),
      forbidden: ErrorResponses.forbidden()
    ]
  )

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
end
