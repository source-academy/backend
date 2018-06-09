defmodule CadetWeb.MCQSubmissionController do
  use CadetWeb, :controller

  use PhoenixSwagger

  swagger_path :submit do
    post("/submission/mcq")

    summary("Creates a new submission of a particular MCQ question.")

    security([%{JWT: []}])

    consumes("application/json")
    produces("application/json")

    parameters do
      submission(:body, Schema.ref(:MCQSubmission), "submission", required: true)
    end

    response(200, "OK", Schema.ref(:MCQCorrectness))
    response(400, "Missing parameter(s) or wrong submission type")
    response(401, "Unauthorised")
  end

  def swagger_definitions do
    %{
      MCQSubmission:
        swagger_schema do
          properties do
            questionId(:integer, "The question id", required: true)

            answer(:integer, "The index of the MCQ choice that is the answer", required: true)
          end
        end,
      MCQCorrectness:
        swagger_schema do

          properties do
            correct(:boolean, "Whether the answer submitted was correct")
          end
        end
    }
  end

end
