defmodule CadetWeb.AchievementsController do
  use CadetWeb, :controller

  use PhoenixSwagger

  alias Cadet.Achievements

  def index(conn, _) do
    render(conn, "index.json",
      achievements: Achievements.get_user_achievements(conn.assigns.current_user)
    )
  end

  def update(conn, %{"id" => id, "achievement" => achievement}) do
    case Achievements.insert_or_update_achievement(
           conn.assigns.current_user,
           json_to_achievement(id, achievement)
         ) do
      {:ok, _} ->
        send_resp(conn, 200, "Success")

      {:error, {status, message}} ->
        send_resp(conn, status, message)
    end
  end

  def delete(conn, %{"id" => id}) do
    case Achievements.delete_achievement(conn.assigns.current_user, id) do
      :ok ->
        send_resp(conn, :no_content, "")

      {:error, {status, message}} ->
        send_resp(conn, status, message)
    end
  end

  def delete_goal(conn, %{"id" => achievement_id, "order" => order}) do
    case Achievements.delete_goal(conn.assigns.current_user, achievement_id, order) do
      :ok ->
        send_resp(conn, :no_content, "")

      {:error, {status, message}} ->
        send_resp(conn, status, message)
    end
  end

  defp json_to_achievement(id, json) do
    json
    |> snake_casify_string_keys_recursive()
    |> rename_keys([
      {"deadline", "close_at"},
      {"release", "open_at"},
      {"prerequisite_ids", "prerequisites"}
    ])
    |> case do
      map = %{"view" => view} ->
        map
        |> Map.delete("view")
        |> Map.merge(view |> Map.take([~w(canvas_url description completion_text)]))

      map ->
        map
    end
    |> case do
      map = %{"goals" => goals} ->
        %{map | "goals" => Enum.map(goals, &json_to_goal(&1))}

      map ->
        map
    end
    |> Map.put("id", id)
  end

  defp json_to_goal(json) do
    rename_keys(json, [{"goal_id", "order"}, {"goal_text", "text"}, {"goal_target", "target"}])
  end

  swagger_path :index do
    get("/achievements")

    summary("Gets achievements, including goals and progress")
    security([%{JWT: []}])

    response(200, "OK", Schema.array(:Achievement))
    response(401, "Unauthorised")
  end

  swagger_path :update do
    post("/achievements/{id}")

    summary("Inserts or updates an achievement")

    security([%{JWT: []}])

    parameters do
      achievement(
        :body,
        Schema.ref(:Achievement),
        "The achievement to insert, or properties to update",
        required: true
      )
    end

    response(200, "OK")
    response(401, "Unauthorised")
    response(403, "Forbidden")
  end

  swagger_path :delete do
    PhoenixSwagger.Path.delete("/achievements/{id}")

    summary("Deletes an achievement")
    security([%{JWT: []}])

    parameters do
      id(:path, :integer, "Achievement ID", required: true)
    end

    response(204, "Success")
    response(401, "Unauthorised")
    response(403, "Forbidden")
  end

  swagger_path :delete_goal do
    PhoenixSwagger.Path.delete("/achievements/{id}/goals/{goalId}")

    summary("Deletes an achievement goal")
    security([%{JWT: []}])

    parameters do
      id(:path, :integer, "Achievement ID", required: true)
      goalId(:path, :integer, "Goal ID", required: true)
    end

    response(204, "Success")
    response(401, "Unauthorised")
    response(403, "Unauthorised")
  end

  def swagger_definitions do
    %{
      Achievement:
        swagger_schema do
          description("An achievement")

          properties do
            title(
              :string,
              "Achievement title"
            )

            ability(
              :string,
              "Achievement ability i.e. category"
            )

            cardTileUrl(
              :string,
              "URL of the achievement's background image"
            )

            id(
              :integer,
              "Achievement ID"
            )

            release(
              :string,
              "Open date, in ISO 8601 format"
            )

            deadline(
              :string,
              "Close date, in ISO 8601 format"
            )

            isTask(
              :boolean,
              "Whether the achievement is a task"
            )

            position(
              :integer,
              "Position of the achievement in the list"
            )

            view(
              ref(:AchievementView),
              "View properties"
            )

            goals(
              :array,
              "Achievement goals",
              items: Schema.ref(:AchievementGoal)
            )

            prerequisiteIds(
              array(:integer),
              "Prerequisite achievement IDs"
            )
          end
        end,
      AchievementView:
        swagger_schema do
          description("Achievement view properties")

          properties do
            canvasUrl(
              :string,
              "URL of the image for the view"
            )

            description(
              :string,
              "Achievement description"
            )

            completionText(
              :string,
              "Text to show when achievement is completed"
            )
          end
        end,
      AchievementGoal:
        swagger_schema do
          description("Goals to meet to unlock an achievement")

          properties do
            goalId(
              :integer,
              "Goal ID"
            )

            goalText(
              :string,
              "Text to show when goal is completed"
            )

            goalProgress(
              :integer,
              "Current user's progress towards completing the goal"
            )

            goalTarget(
              :string,
              "Target EXP needed to complete the goal"
            )
          end
        end
    }
  end
end
