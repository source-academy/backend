defmodule CadetWeb.TeamController do
  @moduledoc """
  Controller module for handling team-related actions.
  """

  use CadetWeb, :controller
  use PhoenixSwagger

  import Ecto.Query

  alias Cadet.Repo
  alias Cadet.Accounts.Team

  def index(conn, %{"assessmentid" => assessment_id}) when is_ecto_id(assessment_id) do
    cr = conn.assigns.course_reg

    query =
      from(t in Team,
        where: t.assessment_id == ^assessment_id,
        join: tm in assoc(t, :team_members),
        where: tm.student_id == ^cr.id,
        limit: 1
      )

    team =
      query
      |> Repo.one()
      |> Repo.preload(assessment: [:config], team_members: [student: [:user]])

    if team == nil do
      conn
      |> put_status(:not_found)
      |> text("Team is not found!")
    else
      team_formation_overview = team_to_team_formation_overview(team)

      conn
      |> put_status(:ok)
      |> put_resp_content_type("application/json")
      |> render("index.json", teamFormationOverview: team_formation_overview)
    end
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

  swagger_path :index do
    get("/admin/teams")

    summary("Fetches team formation overview based on assessment ID")

    security([%{JWT: []}])

    parameters do
      assessmentid(:query, :string, "Assessment ID", required: true)
    end

    response(200, "OK", Schema.ref(:TeamFormationOverview))
    response(404, "Not Found")
    response(403, "Forbidden")
  end

  def swagger_definitions do
    %{
      TeamFormationOverview: %{
        "type" => "object",
        "properties" => %{
          "teamId" => %{"type" => "number", "description" => "The ID of the team"},
          "assessmentId" => %{"type" => "number", "description" => "The ID of the assessment"},
          "assessmentName" => %{"type" => "string", "description" => "The name of the assessment"},
          "assessmentType" => %{"type" => "string", "description" => "The type of the assessment"},
          "studentIds" => %{
            "type" => "array",
            "items" => %{"type" => "number"},
            "description" => "List of student IDs"
          },
          "studentNames" => %{
            "type" => "array",
            "items" => %{"type" => "string"},
            "description" => "List of student names"
          }
        },
        "required" => [
          "teamId",
          "assessmentId",
          "assessmentName",
          "assessmentType",
          "studentIds",
          "studentNames"
        ]
      }
    }
  end
end
