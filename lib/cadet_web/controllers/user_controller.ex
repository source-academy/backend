defmodule CadetWeb.UserController do
  @moduledoc """
  Provides information about a user.
  """

  use CadetWeb, :controller
  use PhoenixSwagger
  import Cadet.Assessments
  alias Cadet.Accounts
  alias Cadet.Accounts.CourseRegistrations

  def index(conn, _) do
    user = Accounts.get_user(conn.assigns.current_user.id)
    user_courses = CourseRegistrations.get_courses(conn.assigns.current_user)
    latest = CourseRegistrations.get_user_course(user.id, user.latest_viewed_id)

    %{total_grade: grade, total_xp: xp} = user_total_grade_xp(latest)
    max_grade = user_max_grade(latest)
    story = user_current_story(latest)

    render(
      conn,
      "index.json",
      user: user,
      courses: user_courses,
      latest: latest,
      grade: grade,
      max_grade: max_grade,
      story: story,
      xp: xp
    )
  end
  # def index(conn, _) do
  #   user = user_with_group(conn.assigns.current_user)
  #   %{total_grade: grade, total_xp: xp} = user_total_grade_xp(user)
  #   max_grade = user_max_grade(user)
  #   story = user_current_story(user)

  #   render(
  #     conn,
  #     "index.json",
  #     user: user,
  #     grade: grade,
  #     max_grade: max_grade,
  #     story: story,
  #     xp: xp
  #   )
  # end

  def update_game_states(conn, %{"gameStates" => new_game_states}) do
    user = conn.assigns[:current_user]

    case CourseRegistrations.update_game_states(user, new_game_states) do
      {:ok, %{}} ->
        text(conn, "OK")

      {:error, {status, message}} ->
        conn
        |> put_status(status)
        |> text(message)
    end
  end

  swagger_path :index do
    get("/v2/user")

    summary("Get the name, and latest_viewed_course of a user")

    security([%{JWT: []}])
    produces("application/json")
    response(200, "OK", Schema.ref(:UserInfo))
    response(401, "Unauthorised")
  end

  swagger_path :update_game_states do
    put("/user/game_states")
    summary("Update user's game states")
    security([%{JWT: []}])
    consumes("application/json")

    parameters do
      gameStates(:body, Schema.ref(:UserGameStates), "new game states", required: true)
    end

    response(200, "OK")
  end

  def swagger_definitions do
    %{
      UserInfo:
        swagger_schema do
          title("User")
          description("Basic information about the user")

          properties do
            userId(:integer, "User's ID", required: true)

            name(:string, "Full name of the user", required: true)

            role(
              :string,
              "Role of the user. Can be 'Student', 'Staff', or 'Admin'",
              required: true
            )

            group(
              :string,
              "Group the user belongs to. May be null if the user does not belong to any group.",
              required: true
            )

            story(Schema.ref(:UserStory), "Story to displayed to current user. ")

            grade(
              :integer,
              "Amount of grade. Only provided for 'Student'. " <>
                "Value will be 0 for non-students."
            )

            maxGrade(
              :integer,
              "Total maximum grade achievable based on submitted assessments. " <>
                "Only provided for 'Student'"
            )

            xp(
              :integer,
              "Amount of xp. Only provided for 'Student'. " <> "Value will be 0 for non-students."
            )

            game_states(
              Schema.ref(:UserGameStates),
              "States for user's game, including users' game progress, settings and collectibles.\n"
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
        end,
      UserGameStates:
        swagger_schema do
        end
    }
  end
end
