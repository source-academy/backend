defmodule CadetWeb.IncentivesController do
  use CadetWeb, :controller
  use OpenApiSpex.ControllerSpecs

  alias Cadet.Incentives.{Achievements, Goals}
  alias CadetWeb.ApiSpec.ErrorResponses
  alias CadetWeb.Schemas
  alias OpenApiSpex.Schema

  tags(["Incentives"])
  security([%{"JWT" => []}])

  operation(:index_achievements,
    summary: "Get all achievements in the course",
    parameters: [
      course_id: [in: :path, type: :integer, required: true, description: "Course ID"]
    ],
    responses: [
      ok:
        {"List of achievements", "application/json",
         %Schema{type: :array, items: Schemas.Achievement}},
      unauthorized: ErrorResponses.unauthorised(),
      forbidden: ErrorResponses.forbidden()
    ]
  )

  def index_achievements(conn, _) do
    course_id = conn.assigns.course_reg.course_id
    render(conn, "index_achievements.json", achievements: Achievements.get(course_id))
  end

  operation(:index_goals,
    summary: "Get all goals in the course, including the current user's progress",
    parameters: [
      course_id: [in: :path, type: :integer, required: true, description: "Course ID"]
    ],
    responses: [
      ok:
        {"List of goals with progress", "application/json",
         %Schema{type: :array, items: Schemas.GoalWithProgress}},
      unauthorized: ErrorResponses.unauthorised(),
      forbidden: ErrorResponses.forbidden()
    ]
  )

  def index_goals(conn, _) do
    render(conn, "index_goals_with_progress.json",
      goals: Goals.get_with_progress(conn.assigns.course_reg)
    )
  end

  operation(:update_progress,
    summary: "Insert or update the current user's progress for the specified goal",
    parameters: [
      course_id: [in: :path, type: :integer, required: true, description: "Course ID"],
      uuid: [in: :path, type: :string, required: true, description: "Goal UUID"]
    ],
    request_body:
      {"The goal progress to insert or update", "application/json",
       Schemas.UpdateGoalProgressRequest},
    responses: [
      no_content: "Goal progress updated",
      bad_request: ErrorResponses.bad_request(),
      unauthorized: ErrorResponses.unauthorised(),
      forbidden: ErrorResponses.forbidden()
    ]
  )

  def update_progress(conn, %{"uuid" => uuid, "progress" => progress}) do
    course_reg_id = conn.assigns.course_reg.id

    progress
    |> json_to_progress(uuid, course_reg_id)
    |> Goals.upsert_progress(uuid, course_reg_id)
    |> handle_standard_result(conn)
  end

  defp json_to_progress(json, uuid, course_reg_id) do
    json =
      json
      |> snake_casify_string_keys_recursive()

    %{
      count: Map.get(json, "count"),
      completed: Map.get(json, "completed"),
      goal_uuid: uuid,
      course_reg_id: course_reg_id
    }
  end
end
