defmodule CadetWeb.IncentivesController do
  use CadetWeb, :controller

  use PhoenixSwagger

  alias Cadet.Incentives.{Achievements, Goals}

  def index_achievements(conn, _) do
    course_id = conn.assigns.course_reg.course_id
    render(conn, "index_achievements.json", achievements: Achievements.get(course_id))
  end

  def index_goals(conn, _) do
    render(conn, "index_goals_with_progress.json",
      goals: Goals.get_with_progress(conn.assigns.course_reg)
    )
  end

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

  swagger_path :index_achievements do
    get("/courses/{course_id}/achievements")

    summary("Gets achievements")
    security([%{JWT: []}])

    response(200, "OK", Schema.array(:Achievement))
    response(401, "Unauthorised")
  end

  swagger_path :index_goals do
    get("/courses/{course_id}/self/goals")

    summary("Gets goals, including user's progress")
    security([%{JWT: []}])

    response(200, "OK", Schema.array(:GoalWithProgress))
    response(401, "Unauthorised")
  end

  swagger_path :update_progress do
    post("/courses/{course_id}/self/goals/{uuid}/progress")

    summary("Inserts or updates own goal progress of specifed goal")
    security([%{JWT: []}])

    parameters do
      uuid(:path, :string, "Goal UUID", required: true, format: :uuid)

      progress(
        :body,
        Schema.ref(:GoalProgress),
        "The goal progress to insert or update",
        required: true
      )
    end

    response(204, "Success")
    response(401, "Unauthorised")
  end

  def swagger_definitions do
    %{
      Achievement:
        swagger_schema do
          description("An achievement")

          properties do
            uuid(
              :string,
              "Achievement UUID",
              format: :uuid
            )

            title(
              :string,
              "Achievement title",
              required: true
            )

            xp(
              :integer,
              "XP earned when achievment is completed"
            )

            isVariableXp(
              :boolean,
              "If true, XP awarded will depend on the goal progress"
            )

            cardBackground(
              :string,
              "URL of the achievement's background image"
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
              "Whether the achievement is a task",
              required: true
            )

            position(
              :integer,
              "Position of the achievement in the list",
              required: true
            )

            view(
              ref(:AchievementView),
              "View properties",
              required: true
            )

            goalUuids(
              schema_array(:string, format: :uuid),
              "Goal UUIDs"
            )

            prerequisiteUuids(
              schema_array(:string, format: :uuid),
              "Prerequisite achievement UUIDs"
            )
          end
        end,
      AchievementView:
        swagger_schema do
          description("Achievement view properties")

          properties do
            coverImage(
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
      Goal:
        swagger_schema do
          description("Goals, including user's progress")

          properties do
            uuid(
              :string,
              "Goal UUID",
              format: :uuid
            )

            text(
              :string,
              "Text to show when goal is completed"
            )

            targetCount(
              :integer,
              "When the count reaches this number, goal is completed"
            )

            type(
              :string,
              "Goal type"
            )

            meta(
              :object,
              "Goal satisfication information"
            )
          end
        end,
      GoalWithProgress:
        swagger_schema do
          description("Goals, including user's progress")

          properties do
            uuid(
              :string,
              "Goal UUID",
              format: :uuid
            )

            completed(
              :boolean,
              "Whether the goal has been completed by the user",
              required: true
            )

            text(
              :string,
              "Text to show when goal is completed"
            )

            count(
              :integer,
              "Counter for the progress of the goal",
              required: true
            )

            targetCount(
              :integer,
              "When the count reaches this number, goal is completed",
              required: true
            )

            type(
              :string,
              "Goal type"
            )

            meta(
              :object,
              "Goal satisfication information"
            )
          end
        end,
      GoalProgress:
        swagger_schema do
          description("User's goal progress")

          properties do
            uuid(
              :string,
              "Goal UUID",
              format: :uuid
            )

            completed(
              :boolean,
              "Whether the goal has been completed by the user"
            )

            count(
              :integer,
              "Counter for the progress of the goal"
            )

            userId(
              :integer,
              "User the goal progress belongs to"
            )
          end
        end
    }
  end
end
