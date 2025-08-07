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
    paginated_display = Assessments.all_user_total_xp(course_id, offset, page_size)
    json(conn, paginated_display)
  end
end
