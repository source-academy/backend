defmodule CadetWeb.AssessmentsController do
  use CadetWeb, :controller

  use PhoenixSwagger
  use Arc.Ecto.Schema

  alias Cadet.Assessments
  alias Cadet.Assessments.Image
  alias Cadet.Accounts

  def index(conn, _) do
    assessment_list =
      Assessments.all_assessments()
      |> Enum.map(
        &%{
          id: &1.id,
          title: &1.title,
          type: Atom.to_string(&1.category),
          summary_short: &1.summary_short,
          open_at: DateTime.to_string(&1.open_at),
          close_at: DateTime.to_string(&1.close_at),
          max_xp: &1.max_xp,
          cover_picture: Image.url({&1.cover_picture, &1}, :thumb)
        }
      )
      |> Poison.encode()

    render(conn, "index.json", assessments: assessment_list)
  end

  def show(conn, %{"assessmentId" => assessmentId}) do
    assessment = Poison.encode(Assessments.get_assessment(assessmentId))
    render(conn, "index.json", assessment: assessment)
  end

  def new(conn, %{"studentId" => studentId}) do
    unattempted_assessments = Assessments.all_assessments()
    |> Enum.map(&(%{assessment: &1, 
      submission: Assessments.find_submission(Accounts.get_user(studentId), &1)}))
    |> Enum.filter(&(&1.submission == nil))
    |> Enum.map(&(&1.assessment))
    |> Poison.encode()

    render(conn, "index.json", unattempted_assessments: unattempted_assessments)
  end

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
          items(Schema.ref(:AssessmentOverview))
        end,
      AssessmentOverview:
        swagger_schema do
          properties do
            id(:integer, "The assessment id", required: true)
            title(:string, "The title of the assessment", required: true)
            type(:string, "Either mission/sidequest/path/contest", required: true)
            summary_short(:string, "Short summary", required: true)
            open_at(:string, "The opening date", format: "date-time", required: true)
            close_at(:string, "The closing date", format: "date-time", required: true)

            max_xp(
              :integer,
              "The maximum amount of XP to be earned from this assessment",
              required: true
            )

            cover_picture(:string, "The URL to the cover picture", required: true)
          end
        end,
      Assessment:
        swagger_schema do
          properties do
            id(:integer, "The assessment id", required: true)
            title(:string, "The title of the assessment", required: true)
            type(:string, "Either mission/sidequest/path/contest", required: true)
            summary_long(:string, "Long summary", required: true)
            mission_pdf(:string, "The URL to the assessment pdf")

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
            questionId(:integer, "The question id", required: true)
            questionType(:string, "The question type (mcq/programming)", required: true)
            content(:string, "The question content", required: true)

            choices(
              Schema.new do
                type(:array)
                items(Schema.ref(:MCQChoice))
              end,
              "MCQ choices if question type is mcq"
            )

            solution(:integer, "Solution to a mcq question if it belongs to path assessment")

            answer(
              :string_or_integer,
              "Previous answer for this quesiton (string/int) depending on question type",
              required: true
            )

            library(
              Schema.ref(:Library),
              "The library used for this question (programming questions only)"
            )

            solution_template(:string, "Solution template for programming questions")
          end
        end,
      MCQChoice:
        swagger_schema do
          properties do
            content(:string, "The choice content", required: true)
            hint(:string, "The hint", required: true)
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
