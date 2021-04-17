defmodule CadetWeb.AdminGoalsController do
  use CadetWeb, :controller

  use PhoenixSwagger

  alias Cadet.Incentives.Goals

  def index(conn, _) do
    render(conn, "index.json", goals: Goals.get())
  end

  def bulk_update(conn, %{"goals" => goals}) do
    goals
    |> Enum.map(&json_to_goal(&1))
    |> Goals.upsert_many()
    |> handle_standard_result(conn)
  end

  def update(conn, %{"uuid" => uuid, "goal" => goal}) do
    goal
    |> json_to_goal(uuid)
    |> Goals.upsert()
    |> handle_standard_result(conn)
  end

  def update_progress(conn, %{"uuid" => uuid, "userid" => user_id, "progress" => progress}) do
    user_id = String.to_integer(user_id)
    progress
    |> json_to_progress(uuid, user_id)
    |> Goals.upsert_progress(uuid, user_id)
    |> handle_standard_result(conn)
  end

  def delete(conn, %{"uuid" => uuid}) do
    uuid
    |> Goals.delete()
    |> handle_standard_result(conn)
  end

  defp json_to_goal(json, uuid \\ nil) do
    original_meta = json["meta"]

    json =
      json
      |> snake_casify_string_keys_recursive()
      |> Map.put("meta", original_meta)

    if is_nil(uuid) do
      json
    else
      Map.put(json, "uuid", uuid)
    end
  end

  defp json_to_progress(json, uuid, user_id) do
    json =
      json
      |> snake_casify_string_keys_recursive()

    %{
      count: Map.get(json, "count"),
      completed: Map.get(json, "completed"),
      goal_uuid: uuid,
      user_id: user_id
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
    post("/admin/users/{userid}/goals/{uuid}/progress")

    summary("Inserts or updates own goal progress of specifed goal")
    security([%{JWT: []}])

    parameters do
      uuid(:path, :string, "Goal UUID", required: true, format: :uuid)
      userid(:path, :integer, "User ID", required: true)

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
    response(404, "Goal not found")
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
