defmodule CadetWeb.ProgrammingSubmissionController do
  use CadetWeb, :controller

  use PhoenixSwagger

  swagger_path :submit do
    post("/submission/programming")

    summary("Create/update a submission of a particular programming question.")

    security([%{JWT: []}])

    consumes("application/json")

    parameters do
      submission(:body, Schema.ref(:ProgrammingSubmission), "submission", required: true)
    end

    response(200, "OK")
    response(400, "Missing parameter(s) or wrong submission type")
    response(401, "Unauthorised")
  end

  def swagger_definitions do
    %{
      ProgrammingSubmission:
        swagger_schema do
          properties do
            questionId(:integer, "The question id", required: true)

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
