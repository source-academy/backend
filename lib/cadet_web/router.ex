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

  # Public Pages
  scope "/v1", CadetWeb do
    pipe_through([:api, :auth])

    get("/sourcecast", SourcecastController, :index)
    post("/auth", AuthController, :create)
    post("/auth/refresh", AuthController, :refresh)
    post("/auth/logout", AuthController, :logout)
    get("/chapter", ChaptersController, :index)
  end

  # Authenticated Pages
  scope "/v1", CadetWeb do
    pipe_through([:api, :auth, :ensure_auth])

    resources("/sourcecast", SourcecastController, only: [:create, :delete])

    get("/achievements/", AchievementsController, :index)
    post("/achievements/", AchievementsController, :update)
    post("/achievements/update/", AchievementsController, :edit)    

    delete("/achievements/goals/", AchievementsController, :delete_goal)   

    get("/assessments", AssessmentsController, :index)
    post("/assessments", AssessmentsController, :create)
    delete("/assessments/:assessmentid", AssessmentsController, :delete)
    post("/assessments/:id", AssessmentsController, :show)
    post("/assessments/publish/:assessmentid", AssessmentsController, :publish)
    post("/assessments/update/:assessmentid", AssessmentsController, :update)
    post("/assessments/:assessmentid/submit", AssessmentsController, :submit)
    post("/assessments/question/:questionid/submit", AnswerController, :submit)

    get("/stories", StoriesController, :index)
    post("/stories", StoriesController, :create)
    delete("/stories/:storyid", StoriesController, :delete)
    post("/stories/:storyid", StoriesController, :update)

    get("/assets/:foldername", AssetsController, :index)
    post("/assets/:foldername/*filename", AssetsController, :upload)
    delete("/assets/:foldername/*filename", AssetsController, :delete)

    get("/grading", GradingController, :index)
    get("/grading/summary", GradingController, :grading_summary)
    get("/grading/:submissionid", GradingController, :show)
    post("/grading/:submissionid/unsubmit", GradingController, :unsubmit)
    post("/grading/:submissionid/:questionid", GradingController, :update)

    get("/notification", NotificationController, :index)
    post("/notification/acknowledge", NotificationController, :acknowledge)

    get("/user", UserController, :index)
    put("/user/game_states/clear", UserController, :clear_up_game_states)
    put("/user/game_states/save", UserController, :update_game_states)

    post("/chapter/update/:id", ChaptersController, :update)
  end

  # Other scopes may use custom stacks.
  # scope "/api", CadetWeb do
  #   pipe_through :api
  # end

  def swagger_info do
    %{
      info: %{
        version: "1.0",
        title: "cadet"
      },
      basePath: "/v1",
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
end
