defmodule CadetWeb.AnswerController do
  use CadetWeb, :controller

  use PhoenixSwagger

  swagger_path :submit do
    post("/assessments/question/{questionId}/submit")

    summary("Submit an answer to a question")

    security([%{JWT: []}])

    consumes("application/json")

    parameters do
      answer(:body, Schema.ref(:Answer), "answer", required: true)
    end

    response(200, "OK")
    response(400, "Missing parameter(s) or wrong answer type")
    response(401, "Unauthorised")
  end

  def swagger_definitions do
    %{
      Answer:
        swagger_schema do
          properties do
            answer(
              :string_or_int,
              "answer of appropriate type depending on question type",
              required: true
            )
          end
        end
    }
  end
end
