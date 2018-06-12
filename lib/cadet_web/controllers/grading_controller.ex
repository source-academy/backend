defmodule CadetWeb.GradingController do
  use CadetWeb, :controller

  use PhoenixSwagger

  swagger_path :index do
    get("/grading")

    summary("Get a list of all submissions with current user as the grader.")

    security([%{JWT: []}])

    produces("application/json")

    response(200, "OK", Schema.ref(:Submissions))
    response(401, "Unauthorised")
  end

  swagger_path :show do
    get("/grading/{submissionId}/{questionId}")

    summary("Get information about a specific question in a specific submission to be graded.")

    security([%{JWT: []}])

    produces("application/json")

    parameters do
      submissionId(:path, :integer, "submission id", required: true)
      questionId(:path, :integer, "question id", required: true)
    end

    response(200, "OK", Schema.ref(:GradingInfo))
  end

  def swagger_definitions do
    %{
      Submissions:
        swagger_schema do
          type(:array)
          items(Schema.ref(:Submission))
        end,
      Submission:
        swagger_schema do
          properties do
            submissionId(:integer, "submission id", required: true)
            missionId(:integer, "mission id", required: true)
            studentId(:integer, "student id", required: true)

            questions(
              Schema.new do
                type(:array)
                items(Schema.ref(:Questions))
              end
            )
          end
        end,
      GradingInfo:
        swagger_schema do
          properties do
            answer(Schema.ref(:Answer))
            marks(:integer, "Marks given to this answer", required: true)
            weight(:integer, "the max xp that can be given to this question", required: true)
            comment(:string, "existing comments if present", required: true)
          end
        end,
      Answer:
        swagger_schema do
          properties do
            code(:string, "Code provided by student", required: true)
          end
        end
    }
  end
end
