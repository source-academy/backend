defmodule CadetWeb.UserController do
  @moduledoc """
  Provides information about a user.
  """

  use CadetWeb, :controller
  use OpenApiSpex.ControllerSpecs

  plug(OpenApiSpex.Plug.CastAndValidate,
    render_error: CadetWeb.Plugs.OpenApiErrorRenderer,
    replace_params: false
  )

  require Logger
  alias Cadet.Accounts.CourseRegistrations

  alias Cadet.{Accounts, Assessments}
  alias CadetWeb.ApiSpec.ErrorResponses
  alias CadetWeb.Schemas

  tags(["User"])
  security([%{"JWT" => []}])

  operation(:index,
    summary: "Get the current user, their courses and their latest viewed course configuration",
    responses: [
      ok: {"User information", "application/json", Schemas.UserInfoResponse},
      unauthorized: ErrorResponses.unauthorised()
    ]
  )

  def index(conn, _) do
    user = conn.assigns.current_user
    Logger.info("Fetching user details for user #{user.id}")

    courses = CourseRegistrations.get_courses(conn.assigns.current_user)

    if user.latest_viewed_course_id do
      latest = CourseRegistrations.get_user_course(user.id, user.latest_viewed_course_id)
      xp = Assessments.assessments_total_xp(latest)
      max_xp = Assessments.user_max_xp(latest)
      story = Assessments.user_current_story(latest)

      render(
        conn,
        "index.json",
        user: user,
        courses: courses,
        latest: latest,
        max_xp: max_xp,
        story: story,
        xp: xp
      )
    else
      render(conn, "index.json",
        user: user,
        courses: courses,
        latest: nil,
        max_xp: nil,
        story: nil,
        xp: nil
      )
    end
  end

  operation(:get_latest_viewed,
    summary: "Get the current user's latest viewed course registration and configuration",
    responses: [
      ok: {"Latest viewed course information", "application/json", Schemas.LatestViewedInfo},
      unauthorized: ErrorResponses.unauthorised()
    ]
  )

  def get_latest_viewed(conn, _) do
    user = conn.assigns.current_user
    Logger.info("Fetching latest viewed course for user #{user.id}")

    latest =
      case user.latest_viewed_course_id do
        nil -> nil
        _ -> CourseRegistrations.get_user_course(user.id, user.latest_viewed_course_id)
      end

    get_course_reg_config(conn, latest)
  end

  defp get_course_reg_config(conn, course_reg) when is_nil(course_reg) do
    render(conn, "course.json", latest: nil, story: nil, xp: nil, max_xp: nil)
  end

  defp get_course_reg_config(conn, course_reg) do
    xp = Assessments.assessments_total_xp(course_reg)
    max_xp = Assessments.user_max_xp(course_reg)
    story = Assessments.user_current_story(course_reg)

    render(
      conn,
      "course.json",
      latest: course_reg,
      max_xp: max_xp,
      story: story,
      xp: xp
    )
  end

  operation(:update_latest_viewed,
    summary: "Update the current user's latest viewed course",
    request_body:
      {"The new latest viewed course", "application/json", Schemas.UpdateLatestViewedRequest},
    responses: [
      ok: {"Updated", "text/plain", %OpenApiSpex.Schema{type: :string}},
      bad_request: ErrorResponses.bad_request(),
      unauthorized: ErrorResponses.unauthorised()
    ]
  )

  def update_latest_viewed(conn, %{"courseId" => course_id}) do
    user = conn.assigns.current_user
    Logger.info("Updating latest viewed course to #{course_id} for user #{user.id}")

    case Accounts.update_latest_viewed(conn.assigns.current_user, course_id) do
      {:ok, %{}} ->
        Logger.info("Successfully updated latest viewed course for user #{user.id}.")
        text(conn, "OK")

      {:error, {status, message}} ->
        Logger.error(
          "Failed to update latest viewed course for user #{user.id}. Status: #{status}, Message: #{message}."
        )

        conn
        |> put_status(status)
        |> text(message)
    end
  end

  operation(:update_game_states,
    summary: "Update the current user's game save states in the course",
    parameters: [
      course_id: [in: :path, type: :integer, required: true, description: "Course ID"]
    ],
    request_body: {"The new game states", "application/json", Schemas.UpdateGameStatesRequest},
    responses: [
      ok: {"Updated", "text/plain", %OpenApiSpex.Schema{type: :string}},
      bad_request: ErrorResponses.bad_request(),
      unauthorized: ErrorResponses.unauthorised(),
      forbidden: ErrorResponses.forbidden()
    ]
  )

  def update_game_states(conn, %{"gameStates" => new_game_states}) do
    cr = conn.assigns[:course_reg]

    Logger.info("Updating game states for user #{cr.user_id} in course #{cr.course_id}")

    case CourseRegistrations.update_game_states(cr, new_game_states) do
      {:ok, %{}} ->
        Logger.info("Successfully updated game states for user #{cr.user_id}.")
        text(conn, "OK")

      {:error, {status, message}} ->
        Logger.error(
          "Failed to update game states for user #{cr.user_id}. Status: #{status}, Message: #{message}."
        )

        conn
        |> put_status(status)
        |> text(message)
    end
  end

  operation(:update_research_agreement,
    summary: "Update the user's agreement to the anonymised collection of programs for research",
    parameters: [
      course_id: [in: :path, type: :integer, required: true, description: "Course ID"]
    ],
    request_body:
      {"The research agreement", "application/json", Schemas.UpdateResearchAgreementRequest},
    responses: [
      ok: {"Updated", "text/plain", %OpenApiSpex.Schema{type: :string}},
      bad_request: ErrorResponses.bad_request(),
      unauthorized: ErrorResponses.unauthorised(),
      forbidden: ErrorResponses.forbidden()
    ]
  )

  def update_research_agreement(conn, %{"agreedToResearch" => agreed_to_research}) do
    course_reg = conn.assigns[:course_reg]

    Logger.info(
      "Updating research agreement to #{agreed_to_research} for user #{course_reg.user_id} in course #{course_reg.course_id}"
    )

    case CourseRegistrations.update_research_agreement(course_reg, agreed_to_research) do
      {:ok, %{}} ->
        Logger.info("Successfully updated research agreement for user #{course_reg.user_id}.")

        text(conn, "OK")

      {:error, {status, message}} ->
        Logger.error(
          "Failed to update research agreement for user #{course_reg.user_id}. Status: #{status}, Message: #{message}."
        )

        conn
        |> put_status(status)
        |> text(message)
    end
  end

  operation(:combined_total_xp,
    summary: "Get the current user's total XP from achievements and assessments in the course",
    parameters: [
      course_id: [in: :path, type: :integer, required: true, description: "Course ID"]
    ],
    responses: [
      ok: {"Total XP", "application/json", Schemas.TotalXP},
      unauthorized: ErrorResponses.unauthorised(),
      forbidden: ErrorResponses.forbidden()
    ]
  )

  def combined_total_xp(conn, _) do
    course_id = conn.assigns.course_reg.course_id
    user_id = conn.assigns.course_reg.user_id
    course_reg_id = conn.assigns.course_reg.id
    Logger.info("Calculating total XP for user #{user_id} in course #{course_id}")

    total_xp = Assessments.user_total_xp(course_id, user_id, course_reg_id)

    Logger.info("Successfully calculated total XP for user #{user_id}: #{total_xp}.")

    json(conn, %{totalXp: total_xp})
  end
end
