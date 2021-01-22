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

  def delete(conn, %{"uuid" => uuid}) do
    uuid
    |> Goals.delete()
    |> handle_standard_result(conn)
  end

  defp json_to_goal(json, uuid \\ nil) do
    json =
      json
      |> snake_casify_string_keys_recursive()
      |> rename_keys([
        {"max_exp", "max_xp"}
      ])

    if is_nil(uuid) do
      json
    else
      Map.put(json, "uuid", uuid)
    end
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

  swagger_path :delete do
    PhoenixSwagger.Path.delete("/admin/goals/{id}")

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
