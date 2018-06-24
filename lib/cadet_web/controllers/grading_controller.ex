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
    response(400, "Invalid or missing parameter(s) or submission and/or question not found")
    response(401, "Unauthorised")
  end

  swagger_path :update do
    post("/grading/{submissionId}/{questionId}")

    summary(
      "Update comment and/or marks given to the answer of a particular qurrstion in a submission"
    )

    security([%{JWT: []}])

    consumes("application/json")
    produces("application/json")

    parameters do
      submissionId(:path, :integer, "submission id", required: true)
      questionId(:path, :integer, "question id", required: true)
      grading(:body, Schema.ref(:Grade), "comment given for a question", required: true)
    end

    response(200, "OK")
    response(400, "Invalid or missing parameter(s) or submission and/or question not found")
    response(401, "Unauthorised")
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
            grade(Schema.ref(:Grade))
            max_xp(:integer, "the max xp that can be given to this question", required: true)
          end
        end,
      # Answer:
      #   swagger_schema do
      #     properties do
      #       code(:string, "Code provided by student", required: true)
      #     end
      #   end,
      Grade:
        swagger_schema do
          properties do
            comment(:string, "comment given")
            xp(:integer, "xp given")
          end
        end
    }
  end
end
