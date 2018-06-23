defmodule CadetWeb.AssessmentsController do
  use CadetWeb, :controller

  use PhoenixSwagger

  swagger_path :index do
    get("/assessments")

    summary("Get a list of all assessments")

    security([%{JWT: []}])

    produces("application/json")

    response(200, "OK", Schema.ref(:AssessmentsList))
    response(401, "Unauthorised")
  end

  swagger_path :show do
    get("/assessments/{assessmentId}")

    summary("Get information about one particular assessment.")

    security([%{JWT: []}])

    produces("application/json")

    parameters do
      assessmentId(:path, :integer, "assessment id", required: true)
    end

    response(200, "OK", Schema.ref(:Assessment))
    response(400, "Missing parameter(s) or invalid assessmentId")
    response(401, "Unauthorised")
  end

  def swagger_definitions do
    %{
      AssessmentsList:
        swagger_schema do
          description("A list of all assessments")
          type(:array)
          items(Schema.ref(:Assessment))
        end,
      Assessment:
        swagger_schema do
          properties do
            order(:integer, "The order of showing the assessments", required: true)
            id(:integer, "The assessment id", required: true)
            title(:string, "The title of the assessment", required: true)
            type(:string, "Either mission/sidequest/path/contest", required: true)
            summary_long(:string, "Long summary", required: true)
            summary_short(:string, "Short summary", required: true)
            open_at(:string, "The opening date", format: "date-time", required: true)
            close_at(:string, "The closing date", format: "date-time", required: true)

            max_xp(
              :integer,
              "The maximum amount of XP to be earned from this assessment",
              required: true
            )

            cover_picture(:string, "The URL to the cover picture", required: true)
            mission_pdf(:string, "The URL to the assessment pdf")

            # Questions will only be returned for GET /assessments/{assessmentId}
            questions(Schema.ref(:Questions), "The list of questions for this assessment")
          end
        end,
      Questions:
        swagger_schema do
          description("A list of questions")
          type(:array)
          items(Schema.ref(:Question))
        end,
      Question:
        swagger_schema do
          properties do
            questionId(:integer, "question id", required: true)
            questionType(:string, "the question type (mcq/programming)", required: true)
            content(:string, "the question content", required: true)

            choices(
              Schema.new do
                type(:array)
                items(Schema.ref(:MCQChoice))
              end,
              "mcq choices if question type is mcq"
            )

            answer(
              :string_or_integer,
              "previous answer for this quesiton (string/int) depending on question type",
              required: true
            )

            library(
              Schema.ref(:Library),
              "The library used for this question (programming questions only)"
            )

            solution_template(:string, "solution template for programming questions")
          end
        end,
      MCQChoice:
        swagger_schema do
          properties do
            content(:string, "the choice content", required: true)
            hint(:string, "the hint", required: true)
          end
        end,
      Library:
        swagger_schema do
          properties do
            chapter(:integer)

            globals(
              Schema.new do
                type(:array)

                items(
                  Schema.new do
                    type(:string)
                  end
                )
              end
            )

            externals(
              Schema.new do
                type(:array)

                items(
                  Schema.new do
                    type(:string)
                  end
                )
              end
            )

            files(
              Schema.new do
                type(:array)

                items(
                  Schema.new do
                    type(:string)
                  end
                )
              end
            )
          end
        end
    }
  end
end
