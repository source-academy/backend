defmodule CadetWeb.UserController do
  @moduledoc """
  Provides information about a user.
  """

  use CadetWeb, :controller
  use PhoenixSwagger

  import Cadet.Assessments

  def index(conn, _) do
    user = conn.assigns.current_user
    grade = user_total_grade(user)
    max_grade = user_max_grade(user)
    story = user_current_story(user)
    xp = user_total_xp(user)

    render(
      conn,
      "index.json",
      user: user,
      grade: grade,
      max_grade: max_grade,
      story: story,
      xp: xp
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

            grade(:integer, "Amount of grade. Only provided for 'Student'")

            maxGrade(
              :integer,
              "Total maximum grade achievable based on submitted assessments." <>
                "Only provided for 'Student'"
            )

            xp(:integer, "Amount of xp. Only provided for 'Student'")
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
