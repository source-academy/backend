defmodule CadetWeb.AdminAchievementsController do
  use CadetWeb, :controller
  use OpenApiSpex.ControllerSpecs

  alias Cadet.Incentives.Achievements
  alias CadetWeb.ApiSpec.ErrorResponses
  alias CadetWeb.Schemas

  tags(["Incentives"])
  security([%{"JWT" => []}])

  operation(:bulk_update,
    summary: "Insert or update multiple achievements in the course",
    parameters: [
      course_id: [in: :path, type: :integer, required: true, description: "Course ID"]
    ],
    request_body:
      {"The achievements to insert, or sets of properties to update", "application/json",
       Schemas.BulkUpdateAchievementsRequest},
    responses: [
      no_content: "Achievements inserted or updated",
      unauthorized: ErrorResponses.unauthorised(),
      forbidden: ErrorResponses.forbidden()
    ]
  )

  def bulk_update(conn, %{"achievements" => achievements}) do
    course_reg = conn.assigns.course_reg

    achievements
    |> Enum.map(&json_to_achievement(&1, course_reg.course_id))
    |> Achievements.upsert_many()
    |> handle_standard_result(conn)
  end

  operation(:update,
    summary: "Insert or update a single achievement",
    parameters: [
      course_id: [in: :path, type: :integer, required: true, description: "Course ID"],
      uuid: [
        in: :path,
        type: :string,
        required: true,
        description: "Achievement UUID; takes precedence over any UUID in the payload"
      ]
    ],
    request_body:
      {"The achievement to insert, or properties to update", "application/json",
       Schemas.UpdateAchievementRequest},
    responses: [
      no_content: "Achievement inserted or updated",
      unauthorized: ErrorResponses.unauthorised(),
      forbidden: ErrorResponses.forbidden()
    ]
  )

  def update(conn, %{"uuid" => uuid, "achievement" => achievement}) do
    course_reg = conn.assigns.course_reg

    achievement
    |> json_to_achievement(course_reg.course_id, uuid)
    |> Achievements.upsert()
    |> handle_standard_result(conn)
  end

  operation(:delete,
    summary: "Delete an achievement",
    parameters: [
      course_id: [in: :path, type: :integer, required: true, description: "Course ID"],
      uuid: [in: :path, type: :string, required: true, description: "Achievement UUID"]
    ],
    responses: [
      no_content: "Achievement deleted",
      unauthorized: ErrorResponses.unauthorised(),
      forbidden: ErrorResponses.forbidden(),
      not_found: ErrorResponses.not_found()
    ]
  )

  def delete(conn, %{"uuid" => uuid}) do
    uuid
    |> Achievements.delete()
    |> handle_standard_result(conn)
  end

  defp json_to_achievement(json, course_id, uuid \\ nil) do
    json =
      json
      |> snake_casify_string_keys_recursive()
      |> rename_keys([
        {"deadline", "close_at"},
        {"release", "open_at"},
        {"card_background", "card_tile_url"}
      ])
      |> Map.put("course_id", course_id)
      |> case do
        map = %{"view" => view} ->
          map
          |> Map.delete("view")
          |> Map.merge(
            view
            |> rename_keys([{"cover_image", "canvas_url"}])
            |> Map.take(~w(canvas_url description completion_text))
          )

        map ->
          map
      end

    if is_nil(uuid) do
      json
    else
      Map.put(json, "uuid", uuid)
    end
  end
end
