defmodule CadetWeb.AssessmentsController do
  use CadetWeb, :controller

  use PhoenixSwagger
  require Logger

  alias Cadet.{Assessments, Repo}
  alias CadetWeb.AssessmentsHelpers

  # These roles can save and finalise answers for closed assessments and
  # submitted answers
  @bypass_closed_roles ~w(staff admin)a

  def submit(conn, %{"assessmentid" => assessment_id}) when is_ecto_id(assessment_id) do
    cr = conn.assigns.course_reg

    Logger.info(
      "Submitting assessment #{assessment_id} for user #{cr.id} in course #{cr.course_id}"
    )

    with {:submission, submission} when not is_nil(submission) <-
           {:submission, Assessments.get_submission(assessment_id, cr)},
         {:is_open?, true} <-
           {:is_open?,
            cr.role in @bypass_closed_roles or Assessments.is_open?(submission.assessment)},
         {:ok, _nil} <- Assessments.finalise_submission(submission) do
      Logger.info("Successfully submitted assessment #{assessment_id} for user #{cr.id}.")

      text(conn, "OK")
    else
      {:submission, nil} ->
        Logger.error("Submission not found for assessment #{assessment_id} and user #{cr.id}.")

        conn
        |> put_status(:not_found)
        |> text("Submission not found")

      {:is_open?, false} ->
        Logger.error("Assessment #{assessment_id} is not open for user #{cr.id}.")

        conn
        |> put_status(:forbidden)
        |> text("Assessment not open")

      {:error, {status, message}} ->
        Logger.error(
          "Error submitting assessment #{assessment_id} for user #{cr.id}: #{message} (status: #{status})."
        )

        conn
        |> put_status(status)
        |> text(message)
    end
  end

  def index(conn, _) do
    cr = conn.assigns.course_reg
    Logger.info("Fetching all assessments for user #{cr.id} in course #{cr.course_id}")

    {:ok, assessments} = Assessments.all_assessments(cr)
    assessments = Assessments.format_all_assessments(assessments)

    Logger.info("Successfully fetched #{length(assessments)} assessments for user #{cr.id}.")

    render(conn, "index.json", assessments: assessments)
  end

  def show(conn, %{"assessmentid" => assessment_id}) when is_ecto_id(assessment_id) do
    cr = conn.assigns.course_reg

    Logger.info(
      "Fetching details for assessment #{assessment_id} for user #{cr.id} in course #{cr.course_id}"
    )

    case Assessments.assessment_with_questions_and_answers(assessment_id, cr) do
      {:ok, assessment} ->
        assessment = Assessments.format_assessment_with_questions_and_answers(assessment)

        Logger.info(
          "Successfully fetched details for assessment #{assessment_id} for user #{cr.id}."
        )

        render(conn, "show.json", assessment: assessment)

      {:error, {status, message}} ->
        Logger.error(
          "Error fetching assessment #{assessment_id} for user #{cr.id}: #{message} (status: #{status})."
        )

        send_resp(conn, status, message)
    end
  end

  def unlock(conn, %{"assessmentid" => assessment_id, "password" => password})
      when is_ecto_id(assessment_id) do
    cr = conn.assigns.course_reg

    Logger.info(
      "Attempting to unlock assessment #{assessment_id} for user #{cr.id} in course #{cr.course_id}"
    )

    case Assessments.assessment_with_questions_and_answers(assessment_id, cr, password) do
      {:ok, assessment} ->
        Logger.info("Successfully unlocked assessment #{assessment_id} for user #{cr.id}.")

        render(conn, "show.json", assessment: assessment)

      {:error, {status, message}} ->
        Logger.error(
          "Failed to unlock assessment #{assessment_id} for user #{cr.id}: #{message} (status: #{status})."
        )

        send_resp(conn, status, message)
    end
  end

  def contest_score_leaderboard(conn, %{
        "assessmentid" => assessment_id,
        "course_id" => course_id
      }) do
    count = String.to_integer(conn.params["count"] || "10")

    Logger.info(
      "Fetching contest score leaderboard for assessment #{assessment_id} in course #{course_id}"
    )

    case {:voting_question, Assessments.get_contest_voting_question(assessment_id)} do
      {:voting_question, voting_question} when not is_nil(voting_question) ->
        question_id = Assessments.fetch_associated_contest_question_id(course_id, voting_question)

        result =
          question_id
          |> Assessments.fetch_top_relative_score_answers(count)
          |> Enum.map(fn entry ->
            updated_entry = %{
              entry
              | answer: entry.answer["code"]
            }

            AssessmentsHelpers.build_contest_leaderboard_entry(updated_entry)
          end)

        Logger.info(
          "Successfully fetched contest score leaderboard for assessment #{assessment_id}."
        )

        json(conn, %{leaderboard: result})

      {:voting_question, nil} ->
        Logger.error("Assessment #{assessment_id} is not a contest voting assessment.")

        conn
        |> put_status(:not_found)
        |> text("Not a contest voting assessment")
    end
  end

  def contest_popular_leaderboard(conn, %{
        "assessmentid" => assessment_id,
        "course_id" => course_id
      }) do
    count = String.to_integer(conn.params["count"] || "10")

    Logger.info(
      "Fetching contest popular leaderboard for assessment #{assessment_id} in course #{course_id}"
    )

    case {:voting_question, Assessments.get_contest_voting_question(assessment_id)} do
      {:voting_question, voting_question} when not is_nil(voting_question) ->
        question_id = Assessments.fetch_associated_contest_question_id(course_id, voting_question)

        result =
          question_id
          |> Assessments.fetch_top_popular_score_answers(count)
          |> Enum.map(fn entry ->
            updated_entry = %{
              entry
              | answer: entry.answer["code"]
            }

            AssessmentsHelpers.build_popular_leaderboard_entry(updated_entry)
          end)

        Logger.info(
          "Successfully fetched contest popular leaderboard for assessment #{assessment_id}."
        )

        json(conn, %{leaderboard: result})

      {:voting_question, nil} ->
        Logger.error("Assessment #{assessment_id} is not a contest voting assessment.")

        conn
        |> put_status(:not_found)
        |> text("Not a contest voting assessment")
    end
  end

  def get_all_contests(conn, %{"course_id" => course_id}) do
    Logger.info("Fetching all contests for course #{course_id}")

    contests = Assessments.fetch_all_contests(course_id)

    Logger.info("Successfully fetched all contests for course #{course_id}.")

    json(conn, contests)
  end

  swagger_path :submit do
    post("/courses/{course_id}/assessments/{assessmentId}/submit")
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
    get("/courses/{course_id}/assessments")

    summary("Get a list of all assessments")

    security([%{JWT: []}])

    produces("application/json")

    response(200, "OK", Schema.ref(:AssessmentsList))
    response(401, "Unauthorised")
  end

  swagger_path :show do
    get("/courses/{course_id}/assessments/{assessmentId}")

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
    post("/courses/{course_id}/assessments/{assessmentId}/unlock")

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

            config(Schema.ref(:AssessmentConfig), "The assessment config", required: true)

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

            hasTokenCounter(:boolean, "Does the assessment have Token Counter enabled?")

            maxXp(
              :integer,
              "The maximum XP for this assessment",
              required: true
            )

            xp(:integer, "The XP earned for this assessment", required: true)

            coverImage(:string, "The URL to the cover picture", required: true)

            private(:boolean, "Is this an private assessment?", required: true)

            isPublished(:boolean, "Is the assessment published?", required: true)

            questionCount(:integer, "The number of questions in this assessment", required: true)

            gradedCount(
              :integer,
              "The number of answers in the submission which have been graded",
              required: true
            )

            maxTeamSize(:integer, "The maximum team size allowed", required: true)
          end
        end,
      Assessment:
        swagger_schema do
          properties do
            id(:integer, "The assessment ID", required: true)
            title(:string, "The title of the assessment", required: true)

            config(Schema.ref(:AssessmentConfig), "The assessment config", required: true)

            number(
              :string,
              "The string identifying the relative position of this assessment",
              required: true
            )

            story(:string, "The story that should be shown for this assessment")
            reading(:string, "The reading for this assessment")
            longSummary(:string, "Long summary", required: true)
            hasTokenCounter(:boolean, "Does the assessment have Token Counter enabled?")
            missionPDF(:string, "The URL to the assessment pdf")

            questions(Schema.ref(:Questions), "The list of questions for this assessment")
          end
        end,
      AssessmentConfig:
        swagger_schema do
          description("Assessment config")
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
            type(Schema.ref(:TestcaseType), "One of public/opaque/secret")
          end
        end,
      TestcaseType:
        swagger_schema do
          type(:string)
          enum([:public, :opaque, :secret])
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
      Leaderboard:
        swagger_schema do
          description("A list of top entries for leaderboard")
          type(:array)
          items(Schema.ref(:ContestEntries))
        end,
      ContestEntries:
        swagger_schema do
          properties do
            student_name(:string, "Name of the student", required: true)
            answer(:string, "The code that the student submitted", required: true)
            final_score(:float, "The score that the student obtained", required: true)
          end
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
