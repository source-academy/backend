defmodule CadetWeb.Answer.ProgrammingAnswerController do
  use CadetWeb, :controller

  use PhoenixSwagger

  swagger_path :show do
    get("/answer/programming/{questionId}")

    summary(
      "Obtain answer of a particular programming question submitted previously by current user"
    )

    security([%{JWT: []}])

    produces("application/json")

    parameters do
      questionId(:path, :integer, "question id", required: true)
    end

    response(200, "OK", Schema.ref(:ProgrammingAnswer))

    response(
      400,
      "Missing parameter(s) or wrong answer type or non-existent answer for given questionId"
    )

    response(401, "Unauthorised")
  end

  swagger_path :submit do
    post("/answer/programming")

    summary("Create/update answer of a particular programming question (under the current user).")

    security([%{JWT: []}])

    consumes("application/json")

    parameters do
      answer(:body, Schema.ref(:ProgrammingAnswer), "answer", required: true)
    end

    response(200, "OK")
    response(400, "Missing parameter(s) or wrong answer type")
    response(401, "Unauthorised")
  end

  def swagger_definitions do
    %{
      ProgrammingAnswer:
        swagger_schema do
          properties do
            questionId(:integer, "The question id", required: true)

            submitted(:boolean, "Whether this is the final answer", default: false)

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
