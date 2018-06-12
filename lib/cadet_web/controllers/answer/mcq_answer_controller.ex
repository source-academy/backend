defmodule CadetWeb.Answer.MCQAnswerController do
  use CadetWeb, :controller

  use PhoenixSwagger

  swagger_path :show do
    get("/answer/mcq/{questionId}")

    summary("Obtain answer of a particular MCQ previously submitted by current user")

    security([%{JWT: []}])

    produces("application/json")

    parameters do
      questionId(:path, :integer, "question id", required: true)
    end

    response(200, "OK", Schema.ref(:MCQAnswer))

    response(
      400,
      "Missing parameter(s) or wrong answer type or non-existent answer for given questionId"
    )

    response(401, "Unauthorised")
  end

  swagger_path :submit do
    post("/answer/mcq")

    summary("Create/update answer of a particular MCQ question (under the current user).")

    security([%{JWT: []}])

    consumes("application/json")
    produces("application/json")

    parameters do
      answer(:body, Schema.ref(:MCQAnswer), "answer", required: true)
    end

    response(200, "OK", Schema.ref(:MCQCorrectness))
    response(400, "Missing parameter(s) or wrong answer type or invalid questionId")
    response(401, "Unauthorised")
  end

  def swagger_definitions do
    %{
      MCQAnswer:
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
