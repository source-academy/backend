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

  pipeline :course do
    plug(:assign_course)
  end

  pipeline :ensure_staff do
    plug(:ensure_role, [:staff, :admin])
  end

  scope "/", CadetWeb do
    get("/.well-known/jwks.json", JWKSController, :index)
  end

  # V2 API

  # Public Pages
  scope "/v2", CadetWeb do
    pipe_through([:api, :auth])

    # get("/sourcecast", SourcecastController, :index)
    post("/auth/refresh", AuthController, :refresh)
    post("/auth/login", AuthController, :create)
    post("/auth/logout", AuthController, :logout)
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

  # Authenticated Pages with course
  scope "/v2/courses/:course_id", CadetWeb do
    pipe_through([:api, :auth, :ensure_auth, :course])

    get("/sourcecast", SourcecastController, :index)

    get("/assessments", AssessmentsController, :index)
    get("/assessments/:assessmentid", AssessmentsController, :show)
    post("/assessments/:assessmentid/unlock", AssessmentsController, :unlock)
    post("/assessments/:assessmentid/submit", AssessmentsController, :submit)
    post("/assessments/question/:questionid/answer", AnswerController, :submit)

    get("/achievements", IncentivesController, :index_achievements)

    get("/stories", StoriesController, :index)

    get("/notifications", NotificationsController, :index)
    post("/notifications/acknowledge", NotificationsController, :acknowledge)

    get("/user/total_xp", UserController, :combined_total_xp)
    put("/user/game_states", UserController, :update_game_states)
    put("/user/research_agreement", UserController, :update_research_agreement)

    get("/config", CoursesController, :index)
  end

  # Authenticated Pages
  scope "/v2/courses/:course_id/self", CadetWeb do
    pipe_through([:api, :auth, :ensure_auth, :course])

    get("/goals", IncentivesController, :index_goals)
    post("/goals/:uuid/progress", IncentivesController, :update_progress)
  end

  # Admin pages
  scope "/v2/courses/:course_id/admin", CadetWeb do
    pipe_through([:api, :auth, :ensure_auth, :course, :ensure_staff])

    resources("/sourcecast", AdminSourcecastController, only: [:create, :delete])

    get("/assets/:foldername", AdminAssetsController, :index)
    post("/assets/:foldername/*filename", AdminAssetsController, :upload)
    delete("/assets/:foldername/*filename", AdminAssetsController, :delete)

    post("/assessments", AdminAssessmentsController, :create)
    post("/assessments/:assessmentid", AdminAssessmentsController, :update)
    delete("/assessments/:assessmentid", AdminAssessmentsController, :delete)

    get("/grading", AdminGradingController, :index)
    get("/grading/summary", AdminGradingController, :grading_summary)
    get("/grading/:submissionid", AdminGradingController, :show)
    post("/grading/:submissionid/unsubmit", AdminGradingController, :unsubmit)
    post("/grading/:submissionid/autograde", AdminGradingController, :autograde_submission)
    post("/grading/:submissionid/:questionid", AdminGradingController, :update)

    post(
      "/grading/:submissionid/:questionid/autograde",
      AdminGradingController,
      :autograde_answer
    )

    get("/users", AdminUserController, :index)
    put("/users", AdminUserController, :upsert_users_and_groups)
    get("/users/:course_reg_id/assessments", AdminAssessmentsController, :index)

    # The admin route for getting assessment information for a specifc user
    get(
      "/users/:course_reg_id/assessments/:assessmentid",
      AdminAssessmentsController,
      :get_assessment
    )

    # The admin route for getting total xp of a specific user
    get("/users/:course_reg_id/total_xp", AdminUserController, :combined_total_xp)
    put("/users/:course_reg_id/role", AdminUserController, :update_role)
    delete("/users/:course_reg_id", AdminUserController, :delete_user)
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

    put("/config", AdminCoursesController, :update_course_config)
    get("/config/assessment_configs", AdminCoursesController, :get_assessment_configs)
    put("/config/assessment_configs", AdminCoursesController, :update_assessment_configs)

    delete(
      "/config/assessment_config/:assessment_config_id",
      AdminCoursesController,
      :delete_assessment_config
    )
  end

  # Notifications endpoints
  scope "/v2/notifications/", CadetWeb do
    get("/config/:course_id", NewNotificationsController, :all_noti_configs)
    get("/config/user/:course_reg_id", NewNotificationsController, :get_configurable_noti_configs)

    post("/preference", NewNotificationsController, :create_preference)
    put("/preference/:noti_pref_id", NewNotificationsController, :update_preference)

    get("/options/config/:noti_config_id", NewNotificationsController, :get_config_time_options)
    post("/options", NewNotificationsController, :create_time_option)
    put("/options/:time_option_id", NewNotificationsController, :update_time_option)
    delete("/options/:time_option_id", NewNotificationsController, :delete_time_option)
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
