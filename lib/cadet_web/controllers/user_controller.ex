defmodule CadetWeb.UserController do
  @moduledoc """
  Provides information about a user.
  """

  use CadetWeb, :controller
  use PhoenixSwagger

  # import Ecto.Changeset

  import Cadet.Assessments
  import Cadet.GameStates
  import Ecto.Repo

  def index(conn, _) do
    user = conn.assigns.current_user
    grade = user_total_grade(user)
    max_grade = user_max_grade(user)
    story = user_current_story(user)
    xp = user_total_xp(user)
    game_states = user_game_states(user)
    render(
      conn,
      "index.json",
      user: user,
      grade: grade,
      max_grade: max_grade,
      story: story,
      xp: xp,
      game_states: game_states
    )
  end

  swagger_path :index do
    get("/user")

    summary("Get the name and role of a user")

    security([%{JWT: []}])

    produces("application/json")

    response(200, "OK", Schema.ref(:UserInfo))
    response(401, "Unauthorised")
  end

  def collectibles_update(conn, %{"picnickname" => pic_nickname, "picname" => pic_name}) do
    user = conn.assigns[:current_user]
    Cadet.GameStates.update_collectibles(pic_nickname, pic_name, user)
    '''

    # Error reporting part, to be further implemented.

    case Cadet.GameStates.update_collectibles(pic_nickname, pic_name, user) do
      {:ok, _} ->
        text(conn, "OK")
      {:error, {status, message}} ->
        conn
        |> put_status(status)
        |> text(message)
    end
    '''
  end

  swagger_path :collectibles_update do
    put("/user/collectibles")
    summary("add one collectible to the user")
    security([%{JWT: []}])
    consumes("application/json")
    produces("application/json")
    parameters do
      picNickname(:path, :string, "picture nickname", required: true)
      questionId(:path, :string, "picture name", required: true)
    end
    response(200, "OK")
    response(400, "Invalid parameters")
    response(401, "Unauthorised")
  end

  '''
  # to do
  def save_data_update do

  end

  swagger_path :save_data_update do

  end
  '''

  def swagger_definitions do
    %{
      UserInfo:
        swagger_schema do
          title("User")
          description("Basic information about the user")

          properties do
            name(:string, "Full name of the user", required: true)

            role(
              :string,
              "Role of the user. Can be 'Student', 'Staff', or 'Admin'",
              required: true
            )

            story(Schema.ref(:UserStory), "Story to displayed to current user. ")

            grade(
              :integer,
              "Amount of grade. Only provided for 'Student'." <>
                "Value will be 0 for non-students."
            )

            maxGrade(
              :integer,
              "Total maximum grade achievable based on submitted assessments." <>
                "Only provided for 'Student'"
            )

            xp(
              :integer,
              "Amount of xp. Only provided for 'Student'." <> "Value will be 0 for non-students."
            )

            game_states(
              :map,
              "States for user's game, including users' collectibles and save data." <> " Value will be a map of empty maps for non-students."
            )
          end
        end,
      UserStory:
        swagger_schema do
          properties do
            story(
              :string,
              "Name of story to be displayed to current user. May only be null before start of semester" <>
                " when no assessments are open"
            )

            playStory(
              :boolean,
              "Whether story should be played (false indicates story field should only be used to fetch" <>
                " assets, display open world view)"
            )
          end
        end
    }
  end
end
