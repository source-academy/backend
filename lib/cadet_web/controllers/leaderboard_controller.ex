defmodule CadetWeb.LeaderboardController do
  use CadetWeb, :controller
  use OpenApiSpex.ControllerSpecs

  alias Cadet.Assessments
  alias CadetWeb.ApiSpec.ErrorResponses
  alias CadetWeb.Schemas

  tags(["Leaderboard"])
  security([%{"JWT" => []}])

  operation(:xp_all,
    summary: "Get the total XP of all users in the course",
    parameters: [
      course_id: [in: :path, type: :integer, required: true, description: "Course ID"]
    ],
    responses: [
      ok: {"XP leaderboard", "application/json", Schemas.XPLeaderboardUsers},
      unauthorized: ErrorResponses.unauthorised(),
      forbidden: ErrorResponses.forbidden()
    ]
  )

  def xp_all(conn, %{"course_id" => course_id}) do
    users_with_xp = Assessments.all_user_total_xp(course_id)
    json(conn, %{users: users_with_xp.users})
  end

  operation(:xp_paginated,
    summary: "Get the total XP of all users in the course (paginated)",
    parameters: [
      course_id: [in: :path, type: :integer, required: true, description: "Course ID"],
      offset: [in: :query, type: :integer, required: false, description: "Pagination offset"],
      page_size: [in: :query, type: :integer, required: false, description: "Users per page"]
    ],
    responses: [
      ok: {"XP leaderboard", "application/json", Schemas.XPLeaderboardUsers},
      unauthorized: ErrorResponses.unauthorised(),
      forbidden: ErrorResponses.forbidden()
    ]
  )

  def xp_paginated(conn, %{"course_id" => course_id}) do
    offset = String.to_integer(conn.params["offset"] || "0")
    page_size = String.to_integer(conn.params["page_size"] || "25")

    paginated_display =
      Assessments.all_user_total_xp(course_id, %{offset: offset, limit: page_size})

    json(conn, paginated_display)
  end
end
