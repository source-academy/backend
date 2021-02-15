defmodule CadetWeb.AdminAchievementsController do
  use CadetWeb, :controller

  use PhoenixSwagger

  alias Cadet.Incentives.Achievements

  def bulk_update(conn, %{"achievements" => achievements}) do
    achievements
    |> Enum.map(&json_to_achievement(&1))
    |> Achievements.upsert_many()
    |> handle_standard_result(conn)
  end

  def update(conn, %{"uuid" => uuid, "achievement" => achievement}) do
    achievement
    |> json_to_achievement(uuid)
    |> Achievements.upsert()
    |> handle_standard_result(conn)
  end

  def delete(conn, %{"uuid" => uuid}) do
    uuid
    |> Achievements.delete()
    |> handle_standard_result(conn)
  end

  defp json_to_achievement(json, uuid \\ nil) do
    json =
      json
      |> snake_casify_string_keys_recursive()
      |> rename_keys([
        {"deadline", "close_at"},
        {"release", "open_at"}
      ])
      |> case do
        map = %{"view" => view} ->
          map
          |> Map.delete("view")
          |> Map.merge(view |> Map.take(~w(canvas_url description completion_text)))

        map ->
          map
      end

    if is_nil(uuid) do
      json
    else
      Map.put(json, "uuid", uuid)
    end
  end

  swagger_path :update do
    put("/admin/achievements/{uuid}")

    summary("Inserts or updates an achievement")

    security([%{JWT: []}])

    parameters do
      uuid(:path, :string, "Achievement UUID; takes precendence over UUID in payload",
        required: true,
        format: :uuid
      )

      achievement(
        :body,
        Schema.ref(:Achievement),
        "The achievement to insert, or properties to update",
        required: true
      )
    end

    response(204, "Success")
    response(401, "Unauthorised")
    response(403, "Forbidden")
  end

  swagger_path :bulk_update do
    put("/admin/achievements")

    summary("Inserts or updates achievements")

    security([%{JWT: []}])

    parameters do
      achievement(
        :body,
        Schema.array(:Achievement),
        "The achievements to insert or sets of properties to update",
        required: true
      )
    end

    response(204, "Success")
    response(401, "Unauthorised")
    response(403, "Forbidden")
  end

  swagger_path :delete do
    PhoenixSwagger.Path.delete("/admin/achievements/{uuid}")

    summary("Deletes an achievement")
    security([%{JWT: []}])

    parameters do
      uuid(:path, :string, "Achievement UUID", required: true, format: :uuid)
    end

    response(204, "Success")
    response(401, "Unauthorised")
    response(403, "Forbidden")
    response(404, "Achievement not found")
  end
end
