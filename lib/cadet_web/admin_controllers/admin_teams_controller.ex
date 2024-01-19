defmodule CadetWeb.AdminTeamsController do
  use CadetWeb, :controller
  use PhoenixSwagger
  alias Cadet.Repo

  alias Cadet.Accounts.{Teams, Team}

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

  def update(conn, %{"teamId" => teamId, "assessmentId" => assessmentId, "student_ids" => student_ids}) do
    team = Team
           |> Repo.get!(teamId)
           |> Repo.preload([assessment: [:config], team_members: [student: [:user]]])

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

    response(200, "OK", Schema.array(:TeamsList))
    response(400, "Bad Request")
    response(403, "Forbidden")
  end

  swagger_path :create do
    post("/admin/teams")

    summary("Creates a new team")

    security([%{JWT: []}])

    consumes("application/json")  # Adjust the content type if applicable

    parameters do
      team_params(:body, :AdminCreateTeamPayload, "Team parameters", required: true)
    end

    response(201, "Created")
    response(400, "Bad Request")
    response(403, "Forbidden")
  end

  swagger_path :update do
    post("/admin/teams/{teamId}")

    summary("Updates a team")

    security([%{JWT: []}])

    consumes("application/json")

    parameters do
      teamId(:path, :integer, "Team ID", required: true)

      team(:body, Schema.ref(:AdminUpdateTeamPayload), "Updated team details",
        required: true
      )
    end

    response(200, "OK")
    response(400, "Bad Request")
    response(403, "Forbidden")
  end

  swagger_path :delete do
    PhoenixSwagger.Path.delete("/admin/teams/{teamId}")

    summary("Deletes a team")

    security([%{JWT: []}])

    parameters do
      teamId(:path, :integer, "Team ID", required: true)
    end

    response(200, "OK")
    response(400, "Bad Request")
    response(403, "Forbidden")
  end

  def swagger_definitions do
    %{
      # Schemas for payloads to create or modify data
      AdminCreateTeamPayload: %{
        "type" => "object",
        "properties" => %{
          "name" => %{"type" => "string", "description" => "Team name"},
          "course" => %{"type" => "string", "description" => "Course name"},
          "other_property" => %{"type" => "string", "description" => "Other relevant property"}
        },
        "required" => ["name", "course"]
      },
      AdminUpdateTeamPayload: %{
        "type" => "object",
        "properties" => %{
          "teamId" => %{"type" => "number", "description" => "The existing team id"},
          "assessmentId" => %{"type" => "number", "description" => "The updated assessment id"},
          "student_ids" => %{
            "type" => "array",
            "items" => %{"$ref" => "#/definitions/AdminUpdateStudentId"},
            "description" => "The updated student ids"
          }
        },
        "required" => ["teamId", "assessmentId", "student_ids"]
      },
      AdminUpdateStudentId: %{
        "type" => "object",
        "properties" => %{
          "id" => %{"type" => "number", "description" => "Student ID"}
        },
        "required" => ["id"]
      },
      TeamList: %{
        "type" => "array",
        "items" => %{"$ref" => "#/definitions/TeamItem"}
      },
      TeamItem: %{
        "type" => "object",
        "properties" => %{
          "teamId" => %{"type" => "integer", "description" => "Team ID"},
          "assessmentId" => %{"type" => "integer", "description" => "Assessment ID"},
          "assessmentName" => %{"type" => "string", "description" => "Assessment name"},
          "assessmentType" => %{"type" => "string", "description" => "Assessment type"},
          "studentIds" => %{
            "type" => "array",
            "items" => %{"type" => "integer"},
            "description" => "Student IDs"
          },
          "studentNames" => %{
            "type" => "array",
            "items" => %{"type" => "string"},
            "description" => "Student names"
          }
        },
        "required" => ["teamId", "assessmentId", "assessmentName", "assessmentType", "studentIds", "studentNames"]
      }
    }
  end
end
