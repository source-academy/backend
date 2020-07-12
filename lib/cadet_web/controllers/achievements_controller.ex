defmodule CadetWeb.AchievementsController do
  
  use CadetWeb, :controller

  use PhoenixSwagger

  alias Cadet.Achievements
  alias Cadet.Achievements.AchievementAbility

  # TODO: ???

  def index(conn, _) do
    user = conn.assigns.current_user
    achievements = Achievements.all_achievements(user)

    render(conn, "index.json", achievements: achievements)
  end

  def update(conn, %{"achievements" => achievements}) do
    result = Achievements.update_achievements(achievements)

    case result do
      :ok->
        text(conn, "OK")

      {:error, {status, message}} ->
        conn
        |> put_status(status)
        |> text(message)
    end
  end

  def edit(conn, %{"achievement" => achievement}) do
    result = Achievements.insert_or_update_achievement(achievement)

    case result do
      :ok->
        text(conn, "OK")

      {:error, {status, message}} ->
        conn
        |> put_status(status)
        |> text(message)
    end
  end

  def delete(conn, %{"achievement" => achievement}) do
    result = Achievements.delete_achievement(achievement)

    case result do
      :ok->
        text(conn, "OK")

      {:error, {status, message}} ->
        conn
        |> put_status(status)
        |> text(message)
    end
  end

  def delete_goal(conn, %{"goal" => goal, "achievement" => achievement}) do
    result = Achievements.delete_goal(goal, achievement)

    case result do
      :ok->
        text(conn, "OK")

      {:error, {status, message}} ->
        conn
        |> put_status(status)
        |> text(message)
    end
  end

  swagger_path :index do
    get("/achievements")

    summary("Get list of all achievements")
    security([%{JWT: []}])

    response(200, "OK")
    response(401, "Unauthorised")
  end

  def swagger_definitions do
    %{
      Achievements:
        swagger_schema do
          properties do

            title(
              :string,
              "title of the achievement"
            )

            ability(
              AchievementAbility,
              "ability"
            )

            background_image_url(
              :string,
              "URL of the achievement's background image"
            )

            inferencer_id(
              :integer,
              "id used for reference by inferencer"
            )

            exp(
              :integer,
              "exp awarded for the achievement"
            )

            open_at(
              :string,
              "open date of achievement"
            )

            close_at(
              :string,
              "close date of achievement"
            )

            is_task(
              :boolean,
              "if the achievement is a task or not"
            )

            prerequisite_ids(
              :array,
              "id of the prerequisites of the achievement"
            )

            position(
              :position, 
              "position of achievement in the list"
            )

            modal_image_url(
              :string,
              "url of the image for the modal"
            )

            description(
              :string,
              "description of the achievement"
            )

            goal_text(
              :string,
              "text to reach the goal of the achievement"
            )

            completion_text(
              :string,
              "text to show when goal is met"
            )


          end
        end
    }
  end

end 