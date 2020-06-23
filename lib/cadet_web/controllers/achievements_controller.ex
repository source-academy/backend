defmodule CadetWeb.AchievementsController do
  
  use CadetWeb, :controller

  use PhoenixSwagger

  alias Cadet.Achievements

  @create_achievement_roles ~w(staff admin)a

  def index(conn, _) do
    {:ok, achievements} = Achievements.all_achievements()

    render(conn, "index.json", achievements: achievements)
  end

  def edit(conn, %{"new_achievements" => new_achievements}) do
    result = Achievements.update_achievements(conn.assigns.current_user, new_achievements)

    case result do
      {:ok, _nil} ->
        text(conn, "OK")

      {:error, {status, message}} ->
        conn
        |> put_status(status)
        |> text(message)
    end
  end

end 