defmodule CadetWeb.LeaderboardController do
  use CadetWeb, :controller

  use PhoenixSwagger

  alias Cadet.Assessments

  def xp_all(conn, %{"course_id" => course_id}) do
    users_with_xp = Assessments.all_user_total_xp(course_id)
    json(conn, %{users: users_with_xp.users})
  end

  def xp_paginated(conn, %{"course_id" => course_id}) do
    offset = String.to_integer(conn.params["offset"] || "0")
    page_size = String.to_integer(conn.params["page_size"] || "25")

    paginated_display =
      Assessments.all_user_total_xp(course_id, %{offset: offset, limit: page_size})

    json(conn, paginated_display)
  end

  swagger_path :xp_all do
    get("/courses/{course_id}/leaderboards/xp_all")

    summary("Get all users XP in course")

    security([%{JWT: []}])

    produces("application/json")

    response(200, "OK", Schema.ref(:XPLeaderboardUsers))
    response(401, "Unauthorised")
  end

  swagger_path :xp_paginated do
    get("/courses/{course_id}/leaderboards/xp")

    summary("Get all users XP in course (paginated)")

    security([%{JWT: []}])

    produces("application/json")

    parameters do
      offset(:query, :integer, "Pagination offset", required: false, default: 0)
      page_size(:query, :integer, "Number of users per page", required: false, default: 25)
    end

    response(200, "OK", Schema.ref(:XPLeaderboardUsers))
    response(401, "Unauthorised")
  end

  def swagger_definitions do
    %{
      XPLeaderboardUsers:
        swagger_schema do
          description("XP Leaderboard Response")

          properties do
            users(:array, "List of users in the leaderboard",
              items: %{
                type: :object,
                properties: %{
                  name: %{type: :string, description: "User's full name"},
                  username: %{type: :string, description: "User's login name"},
                  rank: %{type: :integer, description: "User's rank"},
                  user_id: %{type: :integer, description: "User ID"},
                  total_xp: %{type: :integer, description: "User's total XP"}
                }
              }
            )

            total_count(:integer, "Total number of users in the leaderboard (for paginated)")
          end
        end
    }
  end
end
