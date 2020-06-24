defmodule CadetWeb.AchievementsController do
  
  use CadetWeb, :controller

  use PhoenixSwagger

  alias Cadet.Achievements
  alias Cadet.Achievements.AchievementAbility

  @create_achievement_roles ~w(staff admin)a

  def index(conn, _) do
    achievements = Achievements.all_achievements()

    render(conn, "index.json", achievements: achievements)
  end

  def edit(conn, %{"new_achievements" => new_achievements}) do
    result = Achievements.update_achievements(new_achievements)

    case result do
      {:ok, _nil} ->
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
            inferencer_id(
              :integer,
              "id used for reference by inferencer"

            )

            title(
              :string,
              "title of the achievement"

            )

            ability(
              AchievementAbility,
              "ability"

            )

            icon(
              :string,
              "icon name"

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
              "id used for reference by inferencer"

            )

            close_at(
              :string,
              "id used for reference by inferencer"

            )

            is_task(
              :boolean,
              "id used for reference by inferencer"

            )

            prerequisite_ids(
              :array,
              "id used for reference by inferencer"
            )

            goal(
              :integer,
              "id used for reference by inferencer"

            )

            progress(
              :integer,
              "id used for reference by inferencer"

            )

            modal_image_url(
              :string,
              "id used for reference by inferencer"

            )

            description(
              :string,
              "id used for reference by inferencer"
            )

            goal_text(
              :string,
              "id used for reference by inferencer"
            )

            completion_text(
              :string,
              "id used for reference by inferencer"
            )


          end
        end
    }
  end

end 