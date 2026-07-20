defmodule CadetWeb.AssessmentsController do
  use CadetWeb, :controller
  use OpenApiSpex.ControllerSpecs
  require Logger

  alias Cadet.Assessments
  alias CadetWeb.{AssessmentsHelpers, Schemas}
  alias CadetWeb.ApiSpec.ErrorResponses
  alias OpenApiSpex.Schema

  tags(["Assessments"])
  security([%{"JWT" => []}])

  # These roles can save and finalise answers for closed assessments and
  # submitted answers
  @bypass_closed_roles ~w(staff admin)a

  operation(:submit,
    summary: "Finalise the current user's submission for an assessment",
    parameters: [
      course_id: [in: :path, type: :integer, required: true, description: "Course ID"],
      assessmentid: [in: :path, type: :integer, required: true, description: "Assessment ID"]
    ],
    responses: [
      ok: {"Submission finalised", "text/plain", %Schema{type: :string}},
      bad_request: ErrorResponses.bad_request(),
      unauthorized: ErrorResponses.unauthorised(),
      forbidden: ErrorResponses.forbidden(),
      not_found: ErrorResponses.not_found()
    ]
  )

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

  operation(:index,
    summary: "Get all assessments in the course",
    parameters: [
      course_id: [in: :path, type: :integer, required: true, description: "Course ID"]
    ],
    responses: [
      ok:
        {"List of assessments", "application/json",
         %Schema{type: :array, items: Schemas.AssessmentOverview}},
      unauthorized: ErrorResponses.unauthorised(),
      forbidden: ErrorResponses.forbidden()
    ]
  )

  def index(conn, _) do
    cr = conn.assigns.course_reg
    Logger.info("Fetching all assessments for user #{cr.id} in course #{cr.course_id}")

    {:ok, assessments} = Assessments.all_assessments(cr)
    assessments = Assessments.format_all_assessments(assessments)

    Logger.info("Successfully fetched #{length(assessments)} assessments for user #{cr.id}.")

    render(conn, "index.json", assessments: assessments)
  end

  operation(:show,
    summary: "Get one assessment, including questions and the user's answers",
    parameters: [
      course_id: [in: :path, type: :integer, required: true, description: "Course ID"],
      assessmentid: [in: :path, type: :integer, required: true, description: "Assessment ID"]
    ],
    responses: [
      ok: {"The assessment", "application/json", Schemas.Assessment},
      bad_request: ErrorResponses.bad_request(),
      unauthorized: ErrorResponses.unauthorised(),
      forbidden: ErrorResponses.forbidden()
    ]
  )

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

  operation(:unlock,
    summary: "Unlock a password-protected assessment and return it",
    parameters: [
      course_id: [in: :path, type: :integer, required: true, description: "Course ID"],
      assessmentid: [in: :path, type: :integer, required: true, description: "Assessment ID"]
    ],
    request_body: {"The unlock password", "application/json", Schemas.UnlockAssessmentRequest},
    responses: [
      ok: {"The assessment", "application/json", Schemas.Assessment},
      bad_request: ErrorResponses.bad_request(),
      unauthorized: ErrorResponses.unauthorised(),
      forbidden: ErrorResponses.forbidden()
    ]
  )

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

  operation(:contest_score_leaderboard,
    summary: "Get the top contest entries by relative score",
    parameters: [
      course_id: [in: :path, type: :integer, required: true, description: "Course ID"],
      assessmentid: [in: :path, type: :integer, required: true, description: "Assessment ID"],
      count: [in: :query, type: :integer, required: false, description: "Entries (default 10)"]
    ],
    responses: [
      ok: {"The leaderboard", "application/json", Schemas.ContestLeaderboardResponse},
      unauthorized: ErrorResponses.unauthorised(),
      forbidden: ErrorResponses.forbidden(),
      not_found: ErrorResponses.not_found()
    ]
  )

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

  operation(:contest_popular_leaderboard,
    summary: "Get the top contest entries by popular vote",
    parameters: [
      course_id: [in: :path, type: :integer, required: true, description: "Course ID"],
      assessmentid: [in: :path, type: :integer, required: true, description: "Assessment ID"],
      count: [in: :query, type: :integer, required: false, description: "Entries (default 10)"]
    ],
    responses: [
      ok: {"The leaderboard", "application/json", Schemas.ContestLeaderboardResponse},
      unauthorized: ErrorResponses.unauthorised(),
      forbidden: ErrorResponses.forbidden(),
      not_found: ErrorResponses.not_found()
    ]
  )

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

  operation(:get_all_contests,
    summary: "Get all contest assessments in the course",
    parameters: [
      course_id: [in: :path, type: :integer, required: true, description: "Course ID"]
    ],
    responses: [
      ok:
        {"List of contests", "application/json",
         %Schema{type: :array, items: %Schema{type: :object}}},
      unauthorized: ErrorResponses.unauthorised(),
      forbidden: ErrorResponses.forbidden()
    ]
  )

  def get_all_contests(conn, %{"course_id" => course_id}) do
    Logger.info("Fetching all contests for course #{course_id}")

    contests = Assessments.fetch_all_contests(course_id)

    Logger.info("Successfully fetched all contests for course #{course_id}.")

    json(conn, contests)
  end
end
