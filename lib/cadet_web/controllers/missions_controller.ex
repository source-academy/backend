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
            id(:integer, "The mission id", required: true)
            title(:string, "The title of the mission", required: true)
            summary_long(:string, "Long summary", required: true)
            summary_short(:string, "Short summary", required: true)
            close_at(:string, "The closing date", format: "date-time", required: true)

            max_xp(
              :integer,
              "The maximum amount of XP to be earned from this mission",
              required: true
            )

            cover_picture(:string, "The URL to the cover picture", required: true)
            mission_pdf(:string, "The URL to the mission pdf")

            question(
              Schema.new do
                type(:array)
                items(Schema.ref(:ProgrammingQuestion))
              end
            )
          end
        end,
      ProgrammingQuestion:
        swagger_schema do
          properties do
            id(:integer, "The question id", required: true)
            library(Schema.ref(:Library), "The library used for this question", required: true)
            content(:string, "The question itself", required: true)
            solution_template(:string)
          end
        end,
      Library:
        swagger_schema do
          properties do
            version(:integer)

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
