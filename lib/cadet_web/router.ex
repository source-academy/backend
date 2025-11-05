defmodule CadetWeb.Router do
  use CadetWeb, :router

  pipeline :api do
    plug(:accepts, ["json"])
    plug(:fetch_session)
    plug(:put_secure_browser_headers)
  end

  pipeline :auth do
    plug(Cadet.Auth.Pipeline)
    plug(CadetWeb.Plug.AssignCurrentUser)
  end

  pipeline :ensure_auth do
    plug(Guardian.Plug.EnsureAuthenticated)
  end

  pipeline :rate_limit do
    plug(CadetWeb.Plugs.RateLimiter)
  end

  pipeline :course do
    plug(:assign_course)
  end

  pipeline :ensure_staff do
    plug(:ensure_role, [:staff, :admin])
  end

  pipeline :ensure_admin do
    plug(:ensure_role, [:admin])
  end

  scope "/", CadetWeb do
    get("/.well-known/jwks.json", JWKSController, :index)
  end

  scope "/sso" do
    forward("/", Samly.Router)
  end

  # V2 API

  # Public Pages
  scope "/v2", CadetWeb do
    pipe_through([:api, :auth])

    # get("/sourcecast", SourcecastController, :index)
    post("/auth/refresh", AuthController, :refresh)
    post("/auth/login", AuthController, :create)
    post("/auth/logout", AuthController, :logout)
    get("/auth/saml_redirect", AuthController, :saml_redirect)
    get("/auth/saml_redirect_vscode", AuthController, :saml_redirect_vscode)
    get("/auth/exchange", AuthController, :exchange)
  end

  scope "/v2", CadetWeb do
    # no sessions or anything here

    get("/devices/:secret/cert", DevicesController, :get_cert)
    get("/devices/:secret/key", DevicesController, :get_key)
    get("/devices/:secret/client_id", DevicesController, :get_client_id)
    get("/devices/:secret/mqtt_endpoint", DevicesController, :get_mqtt_endpoint)
  end

  # Authenticated Pages without course
  scope "/v2", CadetWeb do
    pipe_through([:api, :auth, :ensure_auth])

    get("/user", UserController, :index)
    get("/user/latest_viewed_course", UserController, :get_latest_viewed)
    put("/user/latest_viewed_course", UserController, :update_latest_viewed)

    post("/config/create", CoursesController, :create)

    get("/devices", DevicesController, :index)
    post("/devices", DevicesController, :register)
    post("/devices/:id", DevicesController, :edit)
    delete("/devices/:id", DevicesController, :deregister)
    get("/devices/:id/ws_endpoint", DevicesController, :get_ws_endpoint)
  end

  # LLM-related endpoints
  scope "/v2/chats", CadetWeb do
    pipe_through([:api, :auth, :ensure_auth, :rate_limit])

    post("", ChatController, :init_chat)
    post("/:conversationId/message", ChatController, :chat)
  end

  # Authenticated Pages with course
  scope "/v2/courses/:course_id", CadetWeb do
    pipe_through([:api, :auth, :ensure_auth, :course])

    get("/sourcecast", SourcecastController, :index)

    get("/assessments", AssessmentsController, :index)
    get("/assessments/:assessmentid", AssessmentsController, :show)
    post("/assessments/:assessmentid/unlock", AssessmentsController, :unlock)
    post("/assessments/:assessmentid/submit", AssessmentsController, :submit)
    post("/assessments/question/:questionid/answer", AnswerController, :submit)

    post(
      "/assessments/question/:questionid/answerLastModified",
      AnswerController,
      :check_last_modified
    )

    get("/achievements", IncentivesController, :index_achievements)
    get("/self/goals", IncentivesController, :index_goals)
    post("/self/goals/:uuid/progress", IncentivesController, :update_progress)

    get("/stories", StoriesController, :index)

    get("/notifications", NotificationsController, :index)
    post("/notifications/acknowledge", NotificationsController, :acknowledge)

    get("/user/total_xp", UserController, :combined_total_xp)
    put("/user/game_states", UserController, :update_game_states)
    put("/user/research_agreement", UserController, :update_research_agreement)

    get("/leaderboards/xp_all", LeaderboardController, :xp_all)
    get("/leaderboards/xp", LeaderboardController, :xp_paginated)

    get(
      "/assessments/:assessmentid/contest_popular_leaderboard",
      AssessmentsController,
      :contest_popular_leaderboard
    )

    get(
      "/assessments/:assessmentid/contest_score_leaderboard",
      AssessmentsController,
      :contest_score_leaderboard
    )

    get("/all_contests", AssessmentsController, :get_all_contests)

    get("/config", CoursesController, :index)

    get("/team/:assessmentid", TeamController, :index)
  end

  # Admin pages (Access: Course administrators only - these routes can cause substantial damage)
  @doc """
    NOTE: This scope must come before the routes for all staff below.

    This is due to the all-staff route "/grading/:submissionid/:questionid", which would pattern match
    and overshadow "/grading/:assessmentid/publish_all_grades".

    If an admin route will overshadow an all-staff route as well, a suggested better solution would be a
    per-route permission level check.
  """
  scope "/v2/courses/:course_id/admin", CadetWeb do
    pipe_through([:api, :auth, :ensure_auth, :course, :ensure_admin])

    get("/assets/:foldername", AdminAssetsController, :index)
    post("/assets/:foldername/*filename", AdminAssetsController, :upload)
    delete("/assets/:foldername/*filename", AdminAssetsController, :delete)

    post("/assessments", AdminAssessmentsController, :create)
    post("/assessments/:assessmentid", AdminAssessmentsController, :update)
    delete("/assessments/:assessmentid", AdminAssessmentsController, :delete)

    get("/grading/all_submissions", AdminGradingController, :index_all_submissions)

    post(
      "/grading/:assessmentid/publish_all_grades",
      AdminGradingController,
      :publish_all_grades
    )

    post(
      "/grading/:assessmentid/unpublish_all_grades",
      AdminGradingController,
      :unpublish_all_grades
    )

    put("/users/:course_reg_id/role", AdminUserController, :update_role)
    delete("/users/:course_reg_id", AdminUserController, :delete_user)

    put("/config", AdminCoursesController, :update_course_config)
    # TODO: Missing corresponding Swagger path entry
    get("/config/assessment_configs", AdminCoursesController, :get_assessment_configs)
    put("/config/assessment_configs", AdminCoursesController, :update_assessment_configs)
    # TODO: Missing corresponding Swagger path entry
    delete(
      "/config/assessment_config/:assessment_config_id",
      AdminCoursesController,
      :delete_assessment_config
    )
  end

  # Admin pages (Access: All staff)
  scope "/v2/courses/:course_id/admin", CadetWeb do
    pipe_through([:api, :auth, :ensure_auth, :course, :ensure_staff])

    resources("/sourcecast", AdminSourcecastController, only: [:create, :delete])

    post(
      "/assessments/:assessmentid/contest_calculate_score",
      AdminAssessmentsController,
      :calculate_contest_score
    )

    post(
      "/assessments/:assessmentid/contest_dispatch_xp",
      AdminAssessmentsController,
      :dispatch_contest_xp
    )

    get("/grading", AdminGradingController, :index)
    get("/grading/summary", AdminGradingController, :grading_summary)

    get("/grading/:submissionid", AdminGradingController, :show)
    post("/grading/:submissionid/unsubmit", AdminGradingController, :unsubmit)
    post("/grading/:submissionid/unpublish_grades", AdminGradingController, :unpublish_grades)
    post("/grading/:submissionid/publish_grades", AdminGradingController, :publish_grades)
    post("/grading/:submissionid/autograde", AdminGradingController, :autograde_submission)
    post("/grading/:submissionid/:questionid", AdminGradingController, :update)

    post(
      "/generate-comments/:answer_id",
      AICodeAnalysisController,
      :generate_ai_comments
    )

    post(
      "/grading/:submissionid/:questionid/autograde",
      AdminGradingController,
      :autograde_answer
    )

    post(
      "/save-final-comment/:answer_id",
      AICodeAnalysisController,
      :save_final_comment
    )

    post(
      "/save-chosen-comments/:submissionid/:questionid",
      AICodeAnalysisController,
      :save_chosen_comments
    )

    get("/users", AdminUserController, :index)
    get("/users/teamformation", AdminUserController, :get_students)
    put("/users", AdminUserController, :upsert_users_and_groups)
    get("/users/:course_reg_id/assessments", AdminAssessmentsController, :index)

    # The admin route for getting assessment information for a specifc user
    # TODO: Missing Swagger path
    get(
      "/users/:course_reg_id/assessments/:assessmentid",
      AdminAssessmentsController,
      :get_assessment
    )

    # The admin route for getting total xp of a specific user
    get("/users/:course_reg_id/total_xp", AdminUserController, :combined_total_xp)
    get("/users/:course_reg_id/goals", AdminGoalsController, :index_goals_with_progress)
    post("/users/:course_reg_id/goals/:uuid/progress", AdminGoalsController, :update_progress)

    put("/achievements", AdminAchievementsController, :bulk_update)
    put("/achievements/:uuid", AdminAchievementsController, :update)
    delete("/achievements/:uuid", AdminAchievementsController, :delete)

    get("/goals", AdminGoalsController, :index)
    put("/goals", AdminGoalsController, :bulk_update)
    put("/goals/:uuid", AdminGoalsController, :update)
    delete("/goals/:uuid", AdminGoalsController, :delete)

    post("/stories", AdminStoriesController, :create)
    delete("/stories/:storyid", AdminStoriesController, :delete)
    post("/stories/:storyid", AdminStoriesController, :update)

    get("/teams", AdminTeamsController, :index)
    post("/teams", AdminTeamsController, :create)
    delete("/teams/:teamid", AdminTeamsController, :delete)
    put("/teams/:teamid", AdminTeamsController, :update)
    post("/teams/upload", AdminTeamsController, :bulk_upload)
  end

  # Other scopes may use custom stacks.
  # scope "/api", CadetWeb do
  #   pipe_through :api
  # end

  def swagger_info do
    %{
      info: %{
        version: "2.0",
        title: "cadet"
      },
      basePath: "/v2",
      securityDefinitions: %{
        JWT: %{
          type: "apiKey",
          in: "header",
          name: "Authorization"
        }
      }
    }
  end

  scope "/swagger" do
    forward("/", PhoenixSwagger.Plug.SwaggerUI, otp_app: :cadet, swagger_file: "swagger.json")
  end

  scope "/", CadetWeb do
    get("/", DefaultController, :index)
  end

  if Mix.env() == :dev do
    forward("/sent_emails", Bamboo.SentEmailViewerPlug)
  end

  defp assign_course(conn, _opts) do
    course_id = conn.path_params["course_id"]

    course_reg =
      Cadet.Accounts.CourseRegistrations.get_user_record(conn.assigns.current_user.id, course_id)

    case course_reg do
      nil -> conn |> send_resp(403, "Forbidden") |> halt()
      cr -> assign(conn, :course_reg, cr)
    end
  end

  defp ensure_role(conn, opts) do
    if not is_nil(conn.assigns.current_user) and conn.assigns.course_reg.role in opts do
      conn
    else
      conn
      |> send_resp(403, "Forbidden")
      |> halt()
    end
  end
end
