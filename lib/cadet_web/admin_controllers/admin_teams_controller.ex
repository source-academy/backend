defmodule CadetWeb.AdminTeamsController do
  use CadetWeb, :controller
  use OpenApiSpex.ControllerSpecs
  alias Cadet.Repo

  alias Cadet.Accounts.{Teams, Team}
  alias CadetWeb.ApiSpec.ErrorResponses
  alias CadetWeb.Schemas
  alias OpenApiSpex.Schema

  tags(["Teams"])
  security([%{"JWT" => []}])

  operation(:index,
    summary: "Get every team in the course",
    parameters: [
      course_id: [in: :path, type: :integer, required: true, description: "Course ID"]
    ],
    responses: [
      ok:
        {"List of team formation overviews", "application/json",
         %Schema{type: :array, items: Schemas.TeamFormationOverview}},
      bad_request: ErrorResponses.bad_request(),
      unauthorized: ErrorResponses.unauthorised(),
      forbidden: ErrorResponses.forbidden()
    ]
  )

  def index(conn, %{"course_id" => course_id}) do
    teams = Teams.all_teams_for_course(course_id)

    team_formation_overviews =
      teams
      |> Enum.map(&team_to_team_formation_overview/1)

    conn
    |> put_status(:ok)
    |> put_resp_content_type("application/json")
    |> render("index.json", team_formation_overviews: team_formation_overviews)
  end

  defp team_to_team_formation_overview(team) do
    assessment = team.assessment

    team_formation_overview = %{
      teamId: team.id,
      assessmentId: assessment.id,
      assessmentName: assessment.title,
      assessmentType: assessment.config.type,
      studentIds: team.team_members |> Enum.map(& &1.student.user.id),
      studentNames: team.team_members |> Enum.map(& &1.student.user.name)
    }

    team_formation_overview
  end

  operation(:create,
    summary: "Create one or more teams",
    parameters: [
      course_id: [in: :path, type: :integer, required: true, description: "Course ID"]
    ],
    request_body: {"The teams to create", "application/json", Schemas.CreateTeamRequest},
    responses: [
      created: {"Teams created", "text/plain", %Schema{type: :string}},
      bad_request: ErrorResponses.bad_request(),
      unauthorized: ErrorResponses.unauthorised(),
      forbidden: ErrorResponses.forbidden(),
      conflict: ErrorResponses.conflict()
    ]
  )

  def create(conn, %{"team" => team_params}) do
    case Teams.create_team(team_params) do
      {:ok, _team} ->
        conn
        |> put_status(:created)
        |> text("Teams created successfully.")

      {:error, {status, message}} ->
        conn
        |> put_status(status)
        |> text(message)
    end
  end

  operation(:update,
    summary: "Update a team's members",
    parameters: [
      course_id: [in: :path, type: :integer, required: true, description: "Course ID"],
      teamid: [in: :path, type: :integer, required: true, description: "Team ID"]
    ],
    request_body: {"The updated team details", "application/json", Schemas.UpdateTeamRequest},
    responses: [
      ok: {"Team updated", "text/plain", %Schema{type: :string}},
      bad_request: ErrorResponses.bad_request(),
      unauthorized: ErrorResponses.unauthorised(),
      forbidden: ErrorResponses.forbidden(),
      conflict: ErrorResponses.conflict()
    ]
  )

  def update(conn, %{
        "teamId" => teamId,
        "assessmentId" => assessmentId,
        "student_ids" => student_ids
      }) do
    team =
      Team
      |> Repo.get!(teamId)
      |> Repo.preload(assessment: [:config], team_members: [student: [:user]])

    case Teams.update_team(team, assessmentId, student_ids) do
      {:ok, _updated_team} ->
        conn
        |> put_status(:ok)
        |> text("Teams updated successfully.")

      {:error, {status, message}} ->
        conn
        |> put_status(status)
        |> text(message)
    end
  end

  operation(:delete,
    summary: "Delete a team",
    parameters: [
      course_id: [in: :path, type: :integer, required: true, description: "Course ID"],
      teamid: [in: :path, type: :integer, required: true, description: "Team ID"]
    ],
    responses: [
      ok: {"Team deleted", "text/plain", %Schema{type: :string}},
      bad_request: ErrorResponses.bad_request(),
      unauthorized: ErrorResponses.unauthorised(),
      forbidden: ErrorResponses.forbidden(),
      not_found: ErrorResponses.not_found(),
      conflict: ErrorResponses.conflict()
    ]
  )

  def delete(conn, %{"teamId" => team_id}) do
    team = Repo.get(Team, team_id)

    if team do
      case Teams.delete_team(team) do
        {:error, {status, error_message}} ->
          conn
          |> put_status(status)
          |> text(error_message)

        {:ok, _} ->
          text(conn, "Team deleted successfully.")
      end
    else
      conn
      |> put_status(:not_found)
      |> text("Team not found!")
    end
  end

  def delete(conn, %{"course_id" => _course_id, "teamid" => team_id}) do
    delete(conn, %{"teamId" => team_id})
  end

  # FIXME: the route `POST .../admin/teams/upload` (router.ex) points at `bulk_upload`,
  # which does NOT exist -- every call 500s. Left in place per decision (flag, don't
  # delete); tracked in test/cadet_web/api_spec_test.exs @dead_routes. Implement the
  # action or remove the route.
  operation(:bulk_upload, false)
end
