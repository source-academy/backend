defmodule CadetWeb.AssessmentsController do
  use CadetWeb, :controller

  use PhoenixSwagger

  alias Cadet.Assessments

  # These roles can save and finalise answers for closed assessments and
  # submitted answers
  @bypass_closed_roles ~w(staff admin)a

  def submit(conn, %{"assessmentid" => assessment_id}) when is_ecto_id(assessment_id) do
    user = conn.assigns[:current_user]

    with {:submission, submission} when not is_nil(submission) <-
           {:submission, Assessments.get_submission(assessment_id, user)},
         {:is_open?, true} <-
           {:is_open?,
            user.role in @bypass_closed_roles or Assessments.is_open?(submission.assessment)},
         {:ok, _nil} <- Assessments.finalise_submission(submission) do
      text(conn, "OK")
    else
      {:submission, nil} ->
        conn
        |> put_status(:not_found)
        |> text("Submission not found")

      {:is_open?, false} ->
        conn
        |> put_status(:forbidden)
        |> text("Assessment not open")

      {:error, {status, message}} ->
        conn
        |> put_status(status)
        |> text(message)
    end
  end

  def index(conn, _) do
    user = conn.assigns[:current_user]
    {:ok, assessments} = Assessments.all_assessments(user)

    render(conn, "index.json", assessments: assessments)
  end

  def show(conn, %{"assessmentid" => assessment_id}) when is_ecto_id(assessment_id) do
    user = conn.assigns[:current_user]

    case Assessments.assessment_with_questions_and_answers(assessment_id, user) do
      {:ok, assessment} -> render(conn, "show.json", assessment: assessment)
      {:error, {status, message}} -> send_resp(conn, status, message)
    end
  end

  def unlock(conn, %{"assessmentid" => assessment_id, "password" => password})
      when is_ecto_id(assessment_id) do
    user = conn.assigns[:current_user]

    case Assessments.assessment_with_questions_and_answers(assessment_id, user, password) do
      {:ok, assessment} -> render(conn, "show.json", assessment: assessment)
      {:error, {status, message}} -> send_resp(conn, status, message)
    end
  end

  swagger_path :submit do
    post("/assessments/{assessmentId}/submit")
    summary("Finalise submission for an assessment")
    security([%{JWT: []}])

    parameters do
      assessmentId(:path, :integer, "Assessment ID", required: true)
    end

    response(200, "OK")

    response(
      400,
      "Invalid parameters or incomplete submission (submission with unanswered questions)"
    )

    response(403, "User not permitted to answer questions or assessment not open")
    response(404, "Submission not found")
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

    summary("Get information about one particular assessment")

    security([%{JWT: []}])

    consumes("application/json")
    produces("application/json")

    parameters do
      assessmentId(:path, :integer, "Assessment ID", required: true)
    end

    response(200, "OK", Schema.ref(:Assessment))
    response(400, "Missing parameter(s) or invalid assessmentId")
    response(401, "Unauthorised")
  end

  swagger_path :unlock do
    post("/assessments/{assessmentId}/unlock")

    summary("Unlocks a password-protected assessment and returns its information")

    security([%{JWT: []}])

    consumes("application/json")
    produces("application/json")

    parameters do
      assessmentId(:path, :integer, "Assessment ID", required: true)

      password(:body, Schema.ref(:UnlockAssessmentPayload), "Password to unlock assessment",
        required: true
      )
    end

    response(200, "OK", Schema.ref(:Assessment))
    response(400, "Missing parameter(s) or invalid assessmentId")
    response(401, "Unauthorised")
    response(403, "Password incorrect")
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
            id(:integer, "The assessment ID", required: true)
            title(:string, "The title of the assessment", required: true)

            type(Schema.ref(:AssessmentType), "The assessment type", required: true)

            shortSummary(:string, "Short summary", required: true)

            number(
              :string,
              "The string identifying the relative position of this assessment",
              required: true
            )

            story(:string, "The story that should be shown for this assessment")
            reading(:string, "The reading for this assessment")
            openAt(:string, "The opening date", format: "date-time", required: true)
            closeAt(:string, "The closing date", format: "date-time", required: true)

            status(
              Schema.ref(:AssessmentStatus),
              "One of 'not_attempted/attempting/attempted/submitted' indicating whether the assessment has been attempted by the current user",
              required: true
            )

            maxGrade(
              :integer,
              "The maximum grade for this assessment",
              required: true
            )

            maxXp(
              :integer,
              "The maximum XP for this assessment",
              required: true
            )

            xp(:integer, "The XP earned for this assessment", required: true)

            grade(:integer, "The grade earned for this assessment", required: true)

            coverImage(:string, "The URL to the cover picture", required: true)

            private(:boolean, "Is this an private assessment?", required: true)

            isPublished(:boolean, "Is the assessment published?", required: true)

            questionCount(:integer, "The number of questions in this assessment", required: true)

            gradedCount(
              :integer,
              "The number of answers in the submission which have been graded",
              required: true
            )
          end
        end,
      Assessment:
        swagger_schema do
          properties do
            id(:integer, "The assessment ID", required: true)
            title(:string, "The title of the assessment", required: true)

            type(Schema.ref(:AssessmentType), "The assessment type", required: true)

            number(
              :string,
              "The string identifying the relative position of this assessment",
              required: true
            )

            story(:string, "The story that should be shown for this assessment")
            reading(:string, "The reading for this assessment")
            longSummary(:string, "Long summary", required: true)
            missionPDF(:string, "The URL to the assessment pdf")

            questions(Schema.ref(:Questions), "The list of questions for this assessment")
          end
        end,
      AssessmentType:
        swagger_schema do
          description("Assessment type")
          type(:string)
          enum([:mission, :sidequest, :path, :contest, :practical])
        end,
      AssessmentStatus:
        swagger_schema do
          type(:string)
          enum([:not_attempted, :attempting, :attempted, :submitted])
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
            id(:integer, "The question ID", required: true)
            type(:string, "The question type (mcq/programming)", required: true)
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
              # Note: this is technically an invalid type in Swagger/OpenAPI 2.0,
              # but represents that a string or integer could be returned.
              :string_or_integer,
              "Previous answer for this question (string/int) depending on question type",
              required: true
            )

            library(
              Schema.ref(:Library),
              "The library used for this question"
            )

            prepend(:string, "Prepend program for programming questions")
            solutionTemplate(:string, "Solution template for programming questions")
            postpend(:string, "Postpend program for programming questions")

            testcases(
              Schema.new do
                type(:array)
                items(Schema.ref(:Testcase))
              end,
              "Testcase programs for programming questions"
            )

            grader(Schema.ref(:GraderInfo))

            gradedAt(:string, "Last graded at", format: "date-time", required: false)

            xp(:integer, "Final XP given to this question. Only provided for students.")
            grade(:integer, "Final grade given to this question. Only provided for students.")
            comments(:string, "String of comments given to a student's answer", required: false)

            maxGrade(
              :integer,
              "The max grade for this question",
              required: true
            )

            maxXp(
              :integer,
              "The max xp for this question",
              required: true
            )

            autogradingStatus(Schema.ref(:AutogradingStatus), "The status of the autograder")

            autogradingResults(
              Schema.new do
                type(:array)
                items(Schema.ref(:AutogradingResult))
              end
            )
          end
        end,
      MCQChoice:
        swagger_schema do
          properties do
            content(:string, "The choice content", required: true)
            hint(:string, "The hint", required: true)
          end
        end,
      ExternalLibrary:
        swagger_schema do
          properties do
            name(:string, "Name of the external library", required: true)

            symbols(
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

            external(
              Schema.ref(:ExternalLibrary),
              "The external library for this question"
            )
          end
        end,
      Testcase:
        swagger_schema do
          properties do
            answer(:string)
            score(:integer)
            program(:string)
            type(Schema.ref(:TestcaseType), "One of public/hidden/private")
          end
        end,
      TestcaseType:
        swagger_schema do
          type(:string)
          enum([:public, :hidden, :private])
        end,
      AutogradingResult:
        swagger_schema do
          properties do
            resultType(Schema.ref(:AutogradingResultType), "One of pass/fail/error")
            expected(:string)
            actual(:string)
          end
        end,
      AutogradingResultType:
        swagger_schema do
          type(:string)
          enum([:pass, :fail, :error])
        end,
      AutogradingStatus:
        swagger_schema do
          type(:string)
          enum([:none, :processing, :success, :failed])
        end,

      # Schemas for payloads to modify data
      UnlockAssessmentPayload:
        swagger_schema do
          properties do
            password(:string, "Password", required: true)
          end
        end
    }
  end
end
