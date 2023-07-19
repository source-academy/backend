defmodule CadetWeb.AdminTeamsController do
  use CadetWeb, :controller
  use PhoenixSwagger
  alias Cadet.Repo

  alias Cadet.Accounts.{Teams, Team}
  alias CadetWeb.Router.Helpers, as: Routes

  def index(conn, _params) do
    teams = Team
            |> Repo.all()
            |> Repo.preload([assessment: [:config], team_members: [student: [:user]]])

    teamFormationOverviews = teams
      |> Enum.map(&team_to_team_formation_overview/1)

    conn
    |> put_status(:ok)
    |> put_resp_content_type("application/json")
    |> render("index.json", teamFormationOverviews: teamFormationOverviews)
  end

  defp team_to_team_formation_overview(team) do
    assessment = team.assessment

    teamFormationOverview = %{
      teamId: team.id,
      assessmentId: assessment.id,
      assessmentName: assessment.title,
      assessmentType: assessment.config.type,
      studentIds: team.team_members |> Enum.map(&(&1.student.user.id)),
      studentNames: team.team_members |> Enum.map(&(&1.student.user.name))
    }

    teamFormationOverview
  end

  def create(conn, %{"team" => team_params}) do
    case Teams.create_team(team_params) do
      {:ok, team} ->
        conn
        |> put_flash(:info, "Team created successfully.")
        |> render("create.json", team: team)

      {:error, changeset} ->
        render(conn, "create.json", changeset: changeset)
    end
  end

  def update(conn, %{"id" => id, "team" => team_params}) do
    team = Teams
           |> Repo.get!(id)
           |> Repo.preload([:assessment, team_members: [:student]])

    case Teams.update_team(team, team_params) do
      {:ok, updated_team} ->
        conn
        |> put_flash(:info, "Team updated successfully.")
        |> redirect(to: Routes.admin_teams_path(conn, :show, updated_team))

      {:error, changeset} ->
        render(conn, "edit.json", team: team, changeset: changeset)
    end
  end

  def bulk_upload(conn, %{"teams" => teams_params}) do
    case Teams.bulk_upload_teams(teams_params) do
      {:ok, _teams} ->
        text(conn, "Teams uploaded successfully.")

      {:error, changesets} ->
        render(conn, "bulk_upload.json", changesets: changesets)
    end
  end

  def delete(conn, %{"id" => id}) do
    team = Teams |> Repo.get!(id)
    {:ok, _} = Teams.delete_team(team)
    text(conn, "Team deleted successfully.")
  end

  swagger_path :index do
    get("/admin/users/{courseRegId}/assessments")

    summary("Fetches assessment overviews of a user")

    security([%{JWT: []}])

    parameters do
      courseRegId(:path, :integer, "Course Reg ID", required: true)
    end

    response(200, "OK", Schema.array(:AssessmentsList))
    response(401, "Unauthorised")
    response(403, "Forbidden")
  end

  swagger_path :create do
    post("/admin/assessments")

    summary("Creates a new team or updates an existing team")

    security([%{JWT: []}])

    consumes("multipart/form-data")

    parameters do
      assessment(:formData, :file, "Assessment to create or update", required: true)
      forceUpdate(:formData, :boolean, "Force update", required: true)
    end

    response(200, "OK")
    response(400, "XML parse error")
    response(403, "Forbidden")
  end

  swagger_path :update do
    post("/admin/assessments/{teamId}")

    summary("Updates a team")

    security([%{JWT: []}])

    consumes("application/json")

    parameters do
      teamId(:path, :integer, "Team ID", required: true)

      team(:body, Schema.ref(:AdminUpdateAssessmentPayload), "Updated team details",
        required: true
      )
    end

    response(200, "OK")
    response(401, "Assessment is already opened")
    response(403, "Forbidden")
  end

  swagger_path :bulk_update do
    post("/admin/assessments/{assessmentId}")

    summary("Updates an assessment")

    security([%{JWT: []}])

    consumes("application/json")

    parameters do
      assessmentId(:path, :integer, "Assessment ID", required: true)

      assessment(:body, Schema.ref(:AdminUpdateAssessmentPayload), "Updated assessment details",
        required: true
      )
    end

    response(200, "OK")
    response(401, "Assessment is already opened")
    response(403, "Forbidden")
  end

  swagger_path :delete do
    PhoenixSwagger.Path.delete("/admin/teams/{assessmentId}")

    summary("Deletes an assessment")

    security([%{JWT: []}])

    parameters do
      assessmentId(:path, :integer, "Assessment ID", required: true)
    end

    response(200, "OK")
    response(403, "Forbidden")
  end
end
