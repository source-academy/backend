defmodule CadetWeb.MissionsController do
  use CadetWeb, :controller

  use PhoenixSwagger

  swagger_path :index do
    get("/missions")

    summary("Get a list of all missions")

    security([%{JWT: []}])

    produces("application/json")

    response(200, "OK", Schema.ref(:MissionsList))
    response(401, "Unauthorised")
  end

  swagger_path :open do
    get("/missions/open")

    summary("Get a list of open missions")

    security([%{JWT: []}])

    produces("application/json")

    response(200, "OK", Schema.ref(:MissionsList))
    response(401, "Unauthorised")
  end

  swagger_path :show do
    get("/missions/{missionId}")

    summary("Get information about one particular mission.")

    security([%{JWT: []}])

    produces("application/json")

    parameters do
      missionId(:path, :integer, "mission id", required: true)
    end

    response(200, "OK", Schema.ref(:Mission))
    response(400, "Missing parameter(s) or invalid missionId")
    response(401, "Unauthorised")
  end

  swagger_path :questions do
    get("/missions/{missionId}/questions")

    summary("Get questions contained inside a mission. Response is either `mcq` or `programming`")

    security([%{JWT: []}])

    produces("application/json")

    parameters do
      missionId(:path, :integer, "mission id", required: true)
    end

    response(200, "OK", Schema.ref(:Questions))
    response(400, "Missing parameter(s) or invalid missionId")
    response(401, "Unauthorised")
  end

  def swagger_definitions do
    %{
      MissionsList:
        swagger_schema do
          description("A list of all missions")
          type(:array)
          items(Schema.ref(:Mission))
        end,
      Mission:
        swagger_schema do
          properties do
            order(:integer, "The order of showing the missions", required: true)
            id(:integer, "The mission id", required: true)
            title(:string, "The title of the mission", required: true)
            category(:string, "Either mission/sidequest/path/contest", required: true)
            summary_long(:string, "Long summary", required: true)
            summary_short(:string, "Short summary", required: true)
            open_at(:string, "The opening date", format: "date-time", required: true)
            close_at(:string, "The closing date", format: "date-time", required: true)

            max_xp(
              :integer,
              "The maximum amount of XP to be earned from this mission",
              required: true
            )

            cover_picture(:string, "The URL to the cover picture", required: true)
            mission_pdf(:string, "The URL to the mission pdf")
          end
        end,
      Questions:
        swagger_schema do
          properties do
            mcq(
              Schema.new do
                type(:array)
                items(Schema.ref(:MCQQuestion))
              end
            )

            programming(
              Schema.new do
                type(:array)
                items(Schema.ref(:ProgrammingQuestion))
              end
            )
          end
        end,
      MCQQuestion:
        swagger_schema do
          properties do
            questionId(:integer, "question id", required: true)
            content(:string, "the question content", required: true)

            choices(
              Schema.new do
                type(:array)
                items(Schema.ref(:MCQChoice))
              end
            )
          end
        end,
      MCQChoice:
        swagger_schema do
          properties do
            content(:string, "the choice content", required: true)
            hint(:string, "the hint", required: true)
          end
        end,
      ProgrammingQuestion:
        swagger_schema do
          properties do
            questionId(:integer, "The question id", required: true)
            library(Schema.ref(:Library), "The library used for this question", required: true)
            content(:string, "The question itself", required: true)
            solution_template(:string)
          end
        end,
      Library:
        swagger_schema do
          properties do
            chapter(:integer)
            sourceChap(:integer)

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
