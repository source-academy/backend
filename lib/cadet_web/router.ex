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

  # scope "/v2/course/:courseid", CadetWeb do
  #   pipe_through([:api, :auth, :ensure_auth, :course])

  #   # routes, more scopes, etc
  # end

  scope "/", CadetWeb do
    get("/.well-known/jwks.json", JWKSController, :index)
  end

  # V2 API

  # Public Pages
  scope "/v2", CadetWeb do
    pipe_through([:api, :auth])

    get("/sourcecast", SourcecastController, :index)
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

  # Authenticated Pages
  scope "/v2/course/:courseid", CadetWeb do
    pipe_through([:api, :auth, :ensure_auth, :course])

    resources("/sourcecast", SourcecastController, only: [:create, :delete])

    get("/assessments", AssessmentsController, :index)
    get("/assessments/:assessmentid", AssessmentsController, :show)
    post("/assessments/:assessmentid/unlock", AssessmentsController, :unlock)
    post("/assessments/:assessmentid/submit", AssessmentsController, :submit)
    post("/assessments/question/:questionid/answer", AnswerController, :submit)

    get("/achievements", IncentivesController, :index_achievements)

    get("/stories", StoriesController, :index)
    post("/stories", StoriesController, :create)
    delete("/stories/:storyid", StoriesController, :delete)
    post("/stories/:storyid", StoriesController, :update)

    get("/notifications", NotificationsController, :index)
    post("/notifications/acknowledge", NotificationsController, :acknowledge)

    get("/user", UserController, :index)
    put("/user/game_states", UserController, :update_game_states)

    get("/config", CoursesController, :index)

    get("/devices", DevicesController, :index)
    post("/devices", DevicesController, :register)
    post("/devices/:id", DevicesController, :edit)
    delete("/devices/:id", DevicesController, :deregister)
    get("/devices/:id/ws_endpoint", DevicesController, :get_ws_endpoint)
  end

  # Authenticated Pages
  scope "/v2/course/:courseid/self", CadetWeb do
    pipe_through([:api, :auth, :ensure_auth, :course])

    get("/goals", IncentivesController, :index_goals)
    post("/goals/:uuid/progress", IncentivesController, :update_progress)
  end

  # Admin pages
  scope "/v2/course/:courseid/admin", CadetWeb do
    pipe_through([:api, :auth, :ensure_auth, :course, :ensure_staff])

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
    post("/users/:userid/goals/:uuid/progress", AdminGoalsController, :update_progress)

    put("/achievements", AdminAchievementsController, :bulk_update)
    put("/achievements/:uuid", AdminAchievementsController, :update)
    delete("/achievements/:uuid", AdminAchievementsController, :delete)

    get("/goals", AdminGoalsController, :index)
    put("/goals", AdminGoalsController, :bulk_update)
    put("/goals/:uuid", AdminGoalsController, :update)
    delete("/goals/:uuid", AdminGoalsController, :delete)

    put("/course_config", AdminCoursesController, :update_course_config)
    put("/assessment_config", AdminCoursesController, :update_assessment_config)
    put("/assessment_types", AdminCoursesController, :update_assessment_types)
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

  defp assign_course(conn, _opts) do
    course_id = conn.path_params["courseid"]

    course_reg =
      Cadet.Accounts.CourseRegistrations.get_user_record(conn.assigns.current_user.id, course_id)

    case course_reg do
      {:ok, cr} ->
        assign(conn, :course_reg, cr)

      {:error, :no_record} ->
        send_resp(conn, 403, "Forbidden") |> halt()

      # :TODO not sure what to put yet
      {:error, :backend_error} ->
        send_resp(conn, 403, "Forbidden") |> halt()
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
