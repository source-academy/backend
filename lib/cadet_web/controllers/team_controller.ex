defmodule CadetWeb.TeamController do
  use CadetWeb, :controller
  use PhoenixSwagger

  import Ecto.Query

  alias Cadet.Repo
  alias Cadet.Accounts.{Teams, Team}
  alias CadetWeb.Router.Helpers, as: Routes

  def index(conn, %{"assessmentid" => assessment_id}) when is_ecto_id(assessment_id) do
    cr = conn.assigns.course_reg
    
    query =
      from(t in Team,
        where: t.assessment_id == ^assessment_id,
        join: tm in assoc(t, :team_members),
        where: tm.student_id == ^cr.id,
        limit: 1
      )
    team = query
      |> Repo.one()
      |> Repo.preload([assessment: [:config], team_members: [student: [:user]]])

    if team == nil do
      conn
      |> put_status(:ok)
      |> text("Team is not found!")
    else
      teamFormationOverview = team_to_team_formation_overview(team)

      conn
      |> put_status(:ok)
      |> put_resp_content_type("application/json")
      |> render("index.json", teamFormationOverview: teamFormationOverview)
    end
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
end
