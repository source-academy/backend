defmodule CadetWeb.ProgrammingSubmissionController do
  use CadetWeb, :controller

  use PhoenixSwagger

  swagger_path :create do
    post("/submission/programming")

    summary("Create a new submission of a particular mission.")

    security([%{JWT: []}])

    consumes("application/json")

    parameters do
      mission_id(:body, :integer, "mission id", required: true)
      answer(:body, Schema.ref(:ProgrammingSubmission), "answer", required: true)
    end

    response(200, "OK")
    response(400, "Missing parameter(s)")
    response(401, "Unauthorised")
  end

  swagger_path :update do
    post("/submission/programming/{submissionId}")

    summary("Updates an existing submission")

    security([%{JWT: []}])

    consumes("application/json")

    parameters do
      submissionId(:path, :integer, "submission id", required: true)
      answer(:body, Schema.ref(:ProgrammingSubmission), "answer", required: true)
    end

    response(200, "OK")
    response(400, "Missing parameter(s))")
    response(401, "Unauthorised")
  end

  def swagger_definitions do
    %{
      ProgrammingSubmission:
        swagger_schema do
          title("Submission for answers to programming questions")

          properties do
            submitted(:boolean, "Whether this is the final submission", default: false)

            answer(
              Schema.new do
                properties do
                  code(:string, "Code submitted", required: true)
                end
              end
            )
          end
        end
    }
  end
end
