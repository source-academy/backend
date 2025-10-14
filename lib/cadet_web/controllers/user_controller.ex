defmodule CadetWeb.UserController do
  @moduledoc """
  Provides information about a user.
  """

  use CadetWeb, :controller
  use PhoenixSwagger
  require Logger
  alias Cadet.Accounts.CourseRegistrations

  alias Cadet.{Accounts, Assessments}

  def index(conn, _) do
    user = conn.assigns.current_user
    Logger.info("Fetching user details for user #{user.id}")

    courses = CourseRegistrations.get_courses(conn.assigns.current_user)

    if user.latest_viewed_course_id do
      latest = CourseRegistrations.get_user_course(user.id, user.latest_viewed_course_id)
      xp = Assessments.assessments_total_xp(latest)
      max_xp = Assessments.user_max_xp(latest)
      story = Assessments.user_current_story(latest)

      render(
        conn,
        "index.json",
        user: user,
        courses: courses,
        latest: latest,
        max_xp: max_xp,
        story: story,
        xp: xp
      )
    else
      render(conn, "index.json",
        user: user,
        courses: courses,
        latest: nil,
        max_xp: nil,
        story: nil,
        xp: nil
      )
    end
  end

  def get_latest_viewed(conn, _) do
    user = conn.assigns.current_user
    Logger.info("Fetching latest viewed course for user #{user.id}")

    latest =
      case user.latest_viewed_course_id do
        nil -> nil
        _ -> CourseRegistrations.get_user_course(user.id, user.latest_viewed_course_id)
      end

    get_course_reg_config(conn, latest)
  end

  defp get_course_reg_config(conn, course_reg) when is_nil(course_reg) do
    render(conn, "course.json", latest: nil, story: nil, xp: nil, max_xp: nil)
  end

  defp get_course_reg_config(conn, course_reg) do
    xp = Assessments.assessments_total_xp(course_reg)
    max_xp = Assessments.user_max_xp(course_reg)
    story = Assessments.user_current_story(course_reg)

    render(
      conn,
      "course.json",
      latest: course_reg,
      max_xp: max_xp,
      story: story,
      xp: xp
    )
  end

  def update_latest_viewed(conn, %{"courseId" => course_id}) do
    user = conn.assigns.current_user
    Logger.info("Updating latest viewed course to #{course_id} for user #{user.id}")

    case Accounts.update_latest_viewed(conn.assigns.current_user, course_id) do
      {:ok, %{}} ->
        Logger.info("Successfully updated latest viewed course for user #{user.id}.")
        text(conn, "OK")

      {:error, {status, message}} ->
        Logger.error(
          "Failed to update latest viewed course for user #{user.id}. Status: #{status}, Message: #{message}."
        )

        conn
        |> put_status(status)
        |> text(message)
    end
  end

  def update_game_states(conn, %{"gameStates" => new_game_states}) do
    cr = conn.assigns[:course_reg]

    Logger.info("Updating game states for user #{cr.user_id} in course #{cr.course_id}")

    case CourseRegistrations.update_game_states(cr, new_game_states) do
      {:ok, %{}} ->
        Logger.info("Successfully updated game states for user #{cr.user_id}.")
        text(conn, "OK")

      {:error, {status, message}} ->
        Logger.error(
          "Failed to update game states for user #{cr.user_id}. Status: #{status}, Message: #{message}."
        )

        conn
        |> put_status(status)
        |> text(message)
    end
  end

  def update_research_agreement(conn, %{"agreedToResearch" => agreed_to_research}) do
    course_reg = conn.assigns[:course_reg]

    Logger.info(
      "Updating research agreement to #{agreed_to_research} for user #{course_reg.user_id} in course #{course_reg.course_id}"
    )

    case CourseRegistrations.update_research_agreement(course_reg, agreed_to_research) do
      {:ok, %{}} ->
        Logger.info("Successfully updated research agreement for user #{course_reg.user_id}.")

        text(conn, "OK")

      {:error, {status, message}} ->
        Logger.error(
          "Failed to update research agreement for user #{course_reg.user_id}. Status: #{status}, Message: #{message}."
        )

        conn
        |> put_status(status)
        |> text(message)
    end
  end

  def combined_total_xp(conn, _) do
    course_id = conn.assigns.course_reg.course_id
    user_id = conn.assigns.course_reg.user_id
    course_reg_id = conn.assigns.course_reg.id
    Logger.info("Calculating total XP for user #{user_id} in course #{course_id}")

    total_xp = Assessments.user_total_xp(course_id, user_id, course_reg_id)

    Logger.info("Successfully calculated total XP for user #{user_id}: #{total_xp}.")

    json(conn, %{totalXp: total_xp})
  end

  swagger_path :index do
    get("/user")

    summary("Get the name, and latest_viewed_course of a user")

    security([%{JWT: []}])
    produces("application/json")
    response(200, "OK", Schema.ref(:IndexInfo))
    response(401, "Unauthorised")
  end

  swagger_path :get_latest_viewed do
    get("/user/latest_viewed_course")

    summary("Get the latest_viewed_course of a user")

    security([%{JWT: []}])
    produces("application/json")
    response(200, "OK", Schema.ref(:LatestViewedInfo))
    response(401, "Unauthorised")
  end

  swagger_path :update_latest_viewed do
    put("/user/latest_viewed_course")
    summary("Update user's latest viewed course")
    security([%{JWT: []}])
    consumes("application/json")

    parameters do
      course_id(:body, :integer, "new latest viewed course", required: true)
    end

    response(200, "OK")
  end

  swagger_path :update_game_states do
    put("/courses/:course_id/user/game_states")
    summary("Update user's game states")
    security([%{JWT: []}])
    consumes("application/json")

    parameters do
      gameStates(:body, Schema.ref(:UserGameStates), "new game states", required: true)
    end

    response(200, "OK")
  end

  swagger_path :update_research_agreement do
    put("/courses/:course_id/user/research_agreement")
    summary("Update the user's agreement to the anonymized collection of programs for research")
    security([%{JWT: []}])
    consumes("application/json")

    parameters do
      course_id(:path, :integer, "course ID", required: true)

      agreedToResearch(
        :body,
        :boolean,
        "whether the user has agreed to participate in the research",
        required: true
      )
    end

    response(200, "OK")
    response(400, "Bad Request")
  end

  swagger_path :combined_total_xp do
    get("/courses/:course_id/user/total_xp")

    summary("Get the user's total XP from achievements and assessments")

    security([%{JWT: []}])
    produces("application/json")

    parameters do
      course_id(:path, :integer, "course ID", required: true)
    end

    response(200, "OK", Schema.ref(:TotalXPInfo))
    response(401, "Unauthorised")
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
      TotalXPInfo:
        swagger_schema do
          title("User Total XP")
          description("the user's total achievement and assessment XP")

          properties do
            totalXp(:integer, "total XP")
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

            maxXp(
              :integer,
              "Total maximum xp achievable based on submitted assessments. " <>
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

            agreed_to_research(
              :boolean,
              "Whether the user as agreed to participate in the collection of anonymized data for research purposes."
            )
          end
        end,
      CourseConfiguration:
        swagger_schema do
          title("Course Configuration")

          properties do
            course_name(:string, "Course name", required: true)
            course_short_name(:string, "Course module code", required: true)
            viewable(:boolean, "Course viewability", required: true)
            enable_game(:boolean, "Enable game", required: true)
            enable_achievements(:boolean, "Enable achievements", required: true)
            enable_overall_leaderboard(:boolean, "Enable overall leaderboard", required: true)
            enable_contest_leaderboard(:boolean, "Enable contest leadeboard", required: true)
            top_leaderboard_display(:integer, "Top leaderboard display", required: true)

            top_contest_leaderboard_display(:integer, "Top contest leaderboard display",
              required: true
            )

            enable_sourcecast(:boolean, "Enable sourcecast", required: true)
            enable_stories(:boolean, "Enable stories", required: true)
            source_chapter(:integer, "Source Chapter number from 1 to 4", required: true)
            source_variant(Schema.ref(:SourceVariant), "Source Variant name", required: true)
            module_help_text(:string, "Module help text", required: true)
            assessment_types(:list, "Assessment Types", required: true)
            assets_prefix(:string, "Assets prefix, used by the game")
          end

          example(%{
            course_name: "Programming Methodology",
            course_short_name: "CS1101S",
            viewable: true,
            enable_game: true,
            enable_achievements: true,
            enable_overall_leaderboard: true,
            enable_contest_leaderboard: true,
            top_leaderboard_display: 100,
            top_contest_leaderboard_display: 10,
            enable_sourcecast: true,
            enable_stories: false,
            source_chapter: 1,
            source_variant: "default",
            module_help_text: "Help text",
            assessment_types: ["Missions", "Quests", "Paths", "Contests", "Others"],
            assets_prefix: "courses-prod/1/"
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
