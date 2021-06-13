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
    user = conn.assigns.current_user
    courses = CourseRegistrations.get_courses(conn.assigns.current_user)

    if user.latest_viewed_id do
      latest = CourseRegistrations.get_user_record(user.id, user.latest_viewed_id)
      %{total_grade: grade, total_xp: xp} = user_total_grade_xp(latest)
      max_grade = user_max_grade(latest)
      story = user_current_story(latest)

      render(
        conn,
        "index.json",
        user: user,
        courses: courses,
        latest: latest,
        grade: grade,
        max_grade: max_grade,
        story: story,
        xp: xp
      )
    else
      render(conn, "index.json",
        user: user,
        courses: courses,
        latest: nil,
        grade: nil,
        max_grade: nil,
        story: nil,
        xp: nil
      )
    end
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

  def get_latest_viewed(conn, _) do
    user = conn.assigns.current_user

    latest =
      case user.latest_viewed_id do
        nil -> nil
        _ -> CourseRegistrations.get_user_record(user.id, user.latest_viewed_id)
      end

    get_course_reg_config(conn, latest)
  end

  def get_course_reg(conn, _) do
    course_reg = conn.assigns.course_reg
    get_course_reg_config(conn, course_reg)
  end

  defp get_course_reg_config(conn, course_reg) when is_nil(course_reg) do
    render(conn, "course.json", latest: nil, grade: nil, max_grade: nil, story: nil, xp: nil)
  end

  defp get_course_reg_config(conn, course_reg) do
    %{total_grade: grade, total_xp: xp} = user_total_grade_xp(course_reg)
    max_grade = user_max_grade(course_reg)
    story = user_current_story(course_reg)

    render(
      conn,
      "course.json",
      latest: course_reg,
      grade: grade,
      max_grade: max_grade,
      story: story,
      xp: xp
    )
  end

  def update_latest_viewed(conn, %{"course_id" => course_id}) do
    case Accounts.update_latest_viewed(conn.assigns.current_user, course_id) do
      {:ok, %{}} ->
        text(conn, "OK")

      {:error, {status, message}} ->
        conn
        |> put_status(status)
        |> text(message)
    end
  end

  def update_game_states(conn, %{"gameStates" => new_game_states}) do
    cr = conn.assigns[:course_reg]

    case CourseRegistrations.update_game_states(cr, new_game_states) do
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
    response(200, "OK", Schema.ref(:IndexInfo))
    response(401, "Unauthorised")
  end

  swagger_path :get_latest_viewed do
    get("/v2/user/latest_viewed")

    summary("Get the latest_viewed_course of a user")

    security([%{JWT: []}])
    produces("application/json")
    response(200, "OK", Schema.ref(:LatestViewedInfo))
    response(401, "Unauthorised")
  end

  swagger_path :update_latest_viewed do
    put("/v2/user/latest_viewed/{course_id}")
    summary("Update user's latest viewed course")
    security([%{JWT: []}])
    consumes("application/json")

    parameters do
      course_id(:path, :integer, "new latest viewed course", required: true)
    end

    response(200, "OK")
  end

  swagger_path :update_game_states do
    put("/v2/course/:course_id/user/game_states")
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
      IndexInfo:
        swagger_schema do
          title("User Index")
          description("user, course_registration and course configuration of the latest course")

          properties do
            user(Schema.ref(:UserInfo), "user info")

            courseRegistration(
              Schema.ref(:CourseRegistration),
              "course registration of the latest viewed course"
            )

            courseConfiguration(
              Schema.ref(:CourseConfiguration),
              "course configuration of the latest viewed course"
            )
          end
        end,
      LatestViewedInfo:
        swagger_schema do
          title("Latest viewed course")
          description("course_registration and course configuration of the latest course")

          properties do
            courseRegistration(
              Schema.ref(:CourseRegistration),
              "course registration of the latest viewed course"
            )

            courseConfiguration(
              Schema.ref(:CourseConfiguration),
              "course configuration of the latest viewed course"
            )
          end
        end,
      UserInfo:
        swagger_schema do
          title("User")
          description("Basic information about the user")

          properties do
            userId(:integer, "User's ID", required: true)
            name(:string, "Full name of the user", required: true)
          end
        end,
      CourseRegistration:
        swagger_schema do
          title("CourseRegistration")
          description("information about the CourseRegistration")

          properties do
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
      CourseConfiguration:
        swagger_schema do
          title("Course Configuration")

          properties do
            name(:string, "Course name", required: true)
            module_code(:string, "Course module code", required: true)
            viewable(:boolean, "Course viewability", required: true)
            enable_game(:boolean, "Enable game", required: true)
            enable_achievements(:boolean, "Enable achievements", required: true)
            enable_sourcecast(:boolean, "Enable sourcecast", required: true)
            source_chapter(:integer, "Source Chapter number from 1 to 4", required: true)
            source_variant(Schema.ref(:SourceVariant), "Source Variant name", required: true)
            module_help_text(:string, "Module help text", required: true)
            assessment_types(:list, "Assessment Types", required: true)
          end

          example(%{
            name: "Programming Methodology",
            module_code: "CS1101S",
            viewable: true,
            enable_game: true,
            enable_achievements: true,
            enable_sourcecast: true,
            source_chapter: 1,
            source_variant: "default",
            module_help_text: "Help text",
            assessment_types: ["Missions", "Quests", "Paths", "Contests", "Others"]
          })
        end,
      SourceVariant:
        swagger_schema do
          type(:string)
          enum([:default, :concurrent, :gpu, :lazy, "non-det", :wasm])
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
