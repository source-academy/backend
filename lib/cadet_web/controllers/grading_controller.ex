defmodule CadetWeb.GradingController do
  use CadetWeb, :controller

  use PhoenixSwagger

  swagger_path :index do
    get("/grading")

    summary("Get a list of all submissions with current user as the grader")

    security([%{JWT: []}])

    produces("application/json")

    response(200, "OK", Schema.ref(:Submissions))
    response(401, "Unauthorised")
  end

  def swagger_definitions do

  end

end
