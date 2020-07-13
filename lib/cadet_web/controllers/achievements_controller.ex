defmodule CadetWeb.AchievementsController do
  
  use CadetWeb, :controller

  use PhoenixSwagger

  alias Cadet.Achievements
  alias Cadet.Achievements.{AchievementGoal, AchievementAbility}

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

  swagger_path :update do
    post("/achievements")

    summary("Updates achievements with a new set")

    security([%{JWT: []}])

    parameters do
      achievements(:body, :json, "Achievements to be updated", required: true)
    end

    response(200, "OK")
    response(401, "Unauthorised")
  end

  swagger_path :edit do
    post("/achievements/update")

    summary("Edits an achievement")
    security([%{JWT: []}])

    parameters do
      achievement(:body, Achievement, "Achievement to be updated", required: true)
    end

    response(200, "OK")
    response(401, "Unauthorised")
  end

  swagger_path :delete do
    PhoenixSwagger.Path.delete("/achievements/")

    summary("Deletes an achievement")
    security([%{JWT: []}])

    parameters do
      achievement(:body, Achievement, "The associated Achievement", required: true)
    end

    response(200, "OK")
    response(401, "Unauthorised")
  end

  swagger_path :delete_goal do
    PhoenixSwagger.Path.delete("/achievements/goals/")

    summary("Deletes a goal of an achievement")
    security([%{JWT: []}])

    parameters do
      goal(:body, AchievementGoal, "The associated goal", required: true)
      achievement(:body, Achievement, "The associated Achievement", required: true)
    end

    response(200, "OK")
    response(401, "Unauthorised")
  end

  def swagger_definitions do
    %{
      Achievements:
        swagger_schema do
          description("The Achievements a Student needs to gain exp")
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
        end, 

      AchievementGoal:
        swagger_schema do
          description("The Goals to fulfill a particular Achievement")
          properties do
            goal_id(
              :integer,
              "id of the goal for the particular achievement"
            )
            goal_text(
              :string,
              "text to show when goal is met"
            )
            goal_progress(
              :integer,
              "student's progress for the goal"
            )
            goal_target(
              :string,
              "target exp needed for the student to complete the goal"
            )
          end 
        end,
    }
  end

end 