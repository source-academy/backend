defmodule CadetWeb.AdminTeamsController do
  use CadetWeb, :controller
  use PhoenixSwagger
  alias Cadet.Repo

  alias Cadet.Accounts.{Teams, Team}

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

  def delete(conn, %{"course_id" => course_id, "teamid" => team_id}) do
    delete(conn, %{"teamId" => team_id})
  end

  swagger_path :index do
    get("/admin/teams")

    summary("Fetches every team in the course")

    security([%{JWT: []}])

    response(200, "OK", :Teams)
    response(400, "Bad Request")
    response(403, "Forbidden")
  end

  swagger_path :create do
    post("/courses/{course_id}/admin/teams")

    summary("Creates a new team")

    security([%{JWT: []}])

    consumes("application/json")

    parameters do
      team_params(:body, :AdminCreateTeamPayload, "Team parameters", required: true)
    end

    response(201, "Created")
    response(400, "Bad Request")
    response(401, "Unauthorised")
    response(403, "Forbidden")
    response(409, "Conflict")
  end

  swagger_path :update do
    post("/courses/{course_id}/admin/teams/{teamId}")

    summary("Updates an existing team")

    security([%{JWT: []}])

    consumes("application/json")

    parameters do
      teamId(:path, :integer, "Team ID", required: true)

      team(:body, Schema.ref(:AdminUpdateTeamPayload), "Updated team details", required: true)
    end

    response(200, "OK")
    response(400, "Bad Request")
    response(401, "Unauthorised")
    response(403, "Forbidden")
    response(409, "Conflict")
  end

  swagger_path :delete do
    PhoenixSwagger.Path.delete("/courses/{course_id}/admin/teams/{teamId}")

    summary("Deletes an existing team")

    security([%{JWT: []}])

    parameters do
      teamId(:path, :integer, "Team ID", required: true)
    end

    response(200, "OK")
    response(400, "Bad Request")
    response(401, "Unauthorised")
    response(403, "Forbidden")
    response(409, "Conflict")
  end

  def swagger_definitions do
    %{
      AdminCreateTeamPayload:
        swagger_schema do
          properties do
            assessmentId(:integer, "Assessment ID")
            studentIds(:array, "Student IDs", items: %{type: :integer})
          end

          required([:assessmentId, :studentIds])
        end,
      AdminUpdateTeamPayload:
        swagger_schema do
          properties do
            teamId(:integer, "Team ID")
            assessmentId(:integer, "Assessment ID")
            studentIds(:integer, "Student IDs", items: %{type: :integer})
          end

          required([:teamId, :assessmentId, :studentIds])
        end,
      Teams:
        swagger_schema do
          type(:array)
          items(Schema.ref(:Team))
        end,
      Team:
        swagger_schema do
          properties do
            id(:integer, "Team Id")
            assessment(Schema.ref(:Assessment))
            team_members(Schema.ref(:TeamMembers))
          end

          required([:id, :assessment, :team_members])
        end,
      TeamMembers:
        swagger_schema do
          type(:array)
          items(Schema.ref(:TeamMember))
        end,
      TeamMember:
        swagger_schema do
          properties do
            id(:integer, "Team Member Id")
            student(Schema.ref(:CourseRegistration))
            team(Schema.ref(:Team))
          end

          required([:id, :student, :team])
        end
    }
  end
end
