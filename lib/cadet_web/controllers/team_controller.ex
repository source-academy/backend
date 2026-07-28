defmodule CadetWeb.TeamController do
  @moduledoc """
  Controller module for handling team-related actions.
  """

  use CadetWeb, :controller
  use OpenApiSpex.ControllerSpecs

  plug(OpenApiSpex.Plug.CastAndValidate,
    render_error: CadetWeb.Plugs.OpenApiErrorRenderer,
    replace_params: false
  )

  import Ecto.Query

  alias Cadet.Repo
  alias Cadet.Accounts.Team
  alias CadetWeb.ApiSpec.ErrorResponses
  alias CadetWeb.Schemas

  tags(["Teams"])
  security([%{"JWT" => []}])

  operation(:index,
    summary: "Get the current user's team formation overview for an assessment",
    parameters: [
      course_id: [in: :path, type: :integer, required: true, description: "Course ID"],
      assessmentid: [in: :path, type: :integer, required: true, description: "Assessment ID"]
    ],
    responses: [
      ok: {"Team formation overview", "application/json", Schemas.TeamFormationOverview},
      bad_request: ErrorResponses.bad_request(),
      unauthorized: ErrorResponses.unauthorised(),
      forbidden: ErrorResponses.forbidden(),
      not_found: ErrorResponses.not_found()
    ]
  )

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
end
