defmodule CadetWeb.AdminGoalsController do
  use CadetWeb, :controller

  use PhoenixSwagger

  alias Cadet.Incentives.Goals
  alias Cadet.Accounts.CourseRegistration

  def index(conn, _) do
    course_id = conn.assigns.course_reg.course_id
    render(conn, "index.json", goals: Goals.get(course_id))
  end

  def index_goals_with_progress(conn, %{"course_reg_id" => course_reg_id}) do
    course_id = conn.assigns.course_reg.course_id
    course_reg = %CourseRegistration{id: String.to_integer(course_reg_id), course_id: course_id}

    render(conn, "index_goals_with_progress.json", goals: Goals.get_with_progress(course_reg))
  end

  def bulk_update(conn, %{"goals" => goals}) do
    course_reg = conn.assigns.course_reg

    goals
    |> Enum.map(&json_to_goal(&1, course_reg.course_id))
    |> Goals.upsert_many()
    |> handle_standard_result(conn)
  end

  def update(conn, %{"uuid" => uuid, "goal" => goal}) do
    course_reg = conn.assigns.course_reg

    goal
    |> json_to_goal(course_reg.course_id, uuid)
    |> Goals.upsert()
    |> handle_standard_result(conn)
  end

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

  swagger_path :index do
    get("/admin/goals")

    summary("Gets goals")
    security([%{JWT: []}])

    response(200, "OK", Schema.array(:Goal))
    response(401, "Unauthorised")
    response(403, "Forbidden")
  end

  swagger_path :index_goals_with_progress do
    get("/admin/goals/{courseRegId}")

    summary("Gets goals and goal progress of a user")
    security([%{JWT: []}])

    parameters do
      courseRegId(:path, :integer, "Course Reg ID", required: true)
    end

    response(200, "OK", Schema.array(:GoalWithProgress))
    response(401, "Unauthorised")
    response(403, "Forbidden")
  end

  swagger_path :update do
    put("/admin/goals/{uuid}")

    summary("Inserts or updates a goal")

    security([%{JWT: []}])

    parameters do
      uuid(:path, :string, "Goal UUID", required: true, format: :uuid)

      goal(
        :body,
        Schema.ref(:Goal),
        "The goal to insert, or properties to update",
        required: true
      )
    end

    response(204, "Success")
    response(401, "Unauthorised")
    response(403, "Forbidden")
  end

  swagger_path :bulk_update do
    put("/admin/goals")

    summary("Inserts or updates goals")

    security([%{JWT: []}])

    parameters do
      goals(
        :body,
        Schema.array(:Goal),
        "The goals to insert or sets of properties to update",
        required: true
      )
    end

    response(204, "Success")
    response(401, "Unauthorised")
    response(403, "Forbidden")
  end

  swagger_path :update_progress do
    post("/admin/users/{courseRegId}/goals/{uuid}/progress")

    summary("Inserts or updates own goal progress of specifed goal")
    security([%{JWT: []}])

    parameters do
      uuid(:path, :string, "Goal UUID", required: true, format: :uuid)
      courseRegId(:path, :integer, "Course Reg ID", required: true)

      progress(
        :body,
        Schema.ref(:GoalProgress),
        "The goal progress to insert or update",
        required: true
      )
    end

    response(204, "Success")
    response(401, "Unauthorised")
    response(403, "Forbidden")
  end

  swagger_path :delete do
    PhoenixSwagger.Path.delete("/admin/goals/{uuid}")

    summary("Deletes a goal")
    security([%{JWT: []}])

    parameters do
      uuid(:path, :string, "Goal UUID", required: true, format: :uuid)
    end

    response(204, "Success")
    response(401, "Unauthorised")
    response(403, "Forbidden")
    response(404, "Goal not found")
  end
end
