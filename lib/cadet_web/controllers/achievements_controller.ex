defmodule CadetWeb.AchievementsController do
  use CadetWeb, :controller

  use PhoenixSwagger

  alias Cadet.Achievements

  @create_achievement_roles ~w(staff admin)a

  def index(conn, _) do
    {:ok, achievements} = Achievements.all_achievements()

    render(conn, "index.json", achievements: achievements)
  end

  def add(conn, ) do
    result = Achievements.add_achievement(conn.assigns.current_user)

    case result do
      {:ok, _nil} ->
        text(conn, "OK")

      {:error, {status, message}} ->
        conn
        |> put_status(status)
        |> text(message)
    end
  end

  def edit(conn, %{"achievementid" => achievement_id, "params" => params}) do
    result = Achievements.edit_achievement(conn.assigns.current_user, assessment_id, params)

    case result do
      {:ok, _nil} ->
        text(conn, "OK")

      {:error, {status, message}} ->
        conn
        |> put_status(status)
        |> text(message)
    end
  end

  def delete(conn, %{"achievementid" => achievement_id}) do
    result = Achievements.delete_achievement(conn.assigns.current_user, assessment_id)

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