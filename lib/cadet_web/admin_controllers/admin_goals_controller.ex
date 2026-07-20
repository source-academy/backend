defmodule CadetWeb.AdminGoalsController do
  use CadetWeb, :controller
  use OpenApiSpex.ControllerSpecs

  alias Cadet.Incentives.Goals
  alias Cadet.Accounts.CourseRegistration
  alias CadetWeb.ApiSpec.ErrorResponses
  alias CadetWeb.Schemas
  alias OpenApiSpex.Schema

  tags(["Incentives"])
  security([%{"JWT" => []}])

  operation(:index,
    summary: "Get all goal definitions in the course",
    parameters: [
      course_id: [in: :path, type: :integer, required: true, description: "Course ID"]
    ],
    responses: [
      ok: {"List of goals", "application/json", %Schema{type: :array, items: Schemas.Goal}},
      unauthorized: ErrorResponses.unauthorised(),
      forbidden: ErrorResponses.forbidden()
    ]
  )

  def index(conn, _) do
    course_id = conn.assigns.course_reg.course_id
    render(conn, "index.json", goals: Goals.get(course_id))
  end

  operation(:index_goals_with_progress,
    summary: "Get all goals and a specific user's progress",
    parameters: [
      course_id: [in: :path, type: :integer, required: true, description: "Course ID"],
      course_reg_id: [
        in: :path,
        type: :integer,
        required: true,
        description: "Course registration ID of the user"
      ]
    ],
    responses: [
      ok:
        {"List of goals with progress", "application/json",
         %Schema{type: :array, items: Schemas.GoalWithProgress}},
      unauthorized: ErrorResponses.unauthorised(),
      forbidden: ErrorResponses.forbidden()
    ]
  )

  def index_goals_with_progress(conn, %{"course_reg_id" => course_reg_id}) do
    course_id = conn.assigns.course_reg.course_id
    course_reg = %CourseRegistration{id: String.to_integer(course_reg_id), course_id: course_id}

    render(conn, "index_goals_with_progress.json", goals: Goals.get_with_progress(course_reg))
  end

  operation(:bulk_update,
    summary: "Insert or update multiple goals",
    parameters: [
      course_id: [in: :path, type: :integer, required: true, description: "Course ID"]
    ],
    request_body:
      {"The goals to insert or update", "application/json", Schemas.BulkUpdateGoalsRequest},
    responses: [
      no_content: "Goals inserted or updated",
      unauthorized: ErrorResponses.unauthorised(),
      forbidden: ErrorResponses.forbidden()
    ]
  )

  def bulk_update(conn, %{"goals" => goals}) do
    course_reg = conn.assigns.course_reg

    goals
    |> Enum.map(&json_to_goal(&1, course_reg.course_id))
    |> Goals.upsert_many()
    |> handle_standard_result(conn)
  end

  operation(:update,
    summary: "Insert or update a single goal",
    parameters: [
      course_id: [in: :path, type: :integer, required: true, description: "Course ID"],
      uuid: [in: :path, type: :string, required: true, description: "Goal UUID"]
    ],
    request_body: {"The goal to insert or update", "application/json", Schemas.UpdateGoalRequest},
    responses: [
      no_content: "Goal inserted or updated",
      unauthorized: ErrorResponses.unauthorised(),
      forbidden: ErrorResponses.forbidden()
    ]
  )

  def update(conn, %{"uuid" => uuid, "goal" => goal}) do
    course_reg = conn.assigns.course_reg

    goal
    |> json_to_goal(course_reg.course_id, uuid)
    |> Goals.upsert()
    |> handle_standard_result(conn)
  end

  operation(:update_progress,
    summary: "Insert or update a user's progress for a goal",
    parameters: [
      course_id: [in: :path, type: :integer, required: true, description: "Course ID"],
      course_reg_id: [
        in: :path,
        type: :integer,
        required: true,
        description: "Course registration ID of the user"
      ],
      uuid: [in: :path, type: :string, required: true, description: "Goal UUID"]
    ],
    request_body:
      {"The goal progress to insert or update", "application/json",
       Schemas.UpdateGoalProgressRequest},
    responses: [
      no_content: "Goal progress inserted or updated",
      unauthorized: ErrorResponses.unauthorised(),
      forbidden: ErrorResponses.forbidden()
    ]
  )

  def update_progress(conn, %{
        "uuid" => uuid,
        "course_reg_id" => course_reg_id,
        "progress" => progress
      }) do
    course_reg_id = String.to_integer(course_reg_id)

    progress
    |> json_to_progress(uuid, course_reg_id)
    |> Goals.upsert_progress(uuid, course_reg_id)
    |> handle_standard_result(conn)
  end

  operation(:delete,
    summary: "Delete a goal",
    parameters: [
      course_id: [in: :path, type: :integer, required: true, description: "Course ID"],
      uuid: [in: :path, type: :string, required: true, description: "Goal UUID"]
    ],
    responses: [
      no_content: "Goal deleted",
      unauthorized: ErrorResponses.unauthorised(),
      forbidden: ErrorResponses.forbidden(),
      not_found: ErrorResponses.not_found()
    ]
  )

  def delete(conn, %{"uuid" => uuid}) do
    course_reg = conn.assigns.course_reg

    uuid
    |> Goals.delete(course_reg.course_id)
    |> handle_standard_result(conn)
  end

  defp json_to_goal(json, course_id, uuid \\ nil) do
    original_meta = json["meta"]

    json =
      json
      |> snake_casify_string_keys_recursive()
      |> Map.put("meta", original_meta)
      |> Map.put("course_id", course_id)

    if is_nil(uuid) do
      json
    else
      Map.put(json, "uuid", uuid)
    end
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
