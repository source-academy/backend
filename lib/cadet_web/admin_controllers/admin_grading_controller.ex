defmodule CadetWeb.AdminGradingController do
  use CadetWeb, :controller
  use OpenApiSpex.ControllerSpecs

  alias Cadet.{Assessments, Courses}
  alias CadetWeb.ApiSpec.ErrorResponses
  alias OpenApiSpex.Schema

  tags(["Grading"])
  security([%{"JWT" => []}])

  @doc """
  # Query Parameters
  - `pageSize`: Integer. The number of submissions to return. Default 10.
  - `offset`: Integer. The number of submissions to skip. Default 0.
  - `title`: String. Assessment title.
  - `status`: String. Submission status.
  - `isFullyGraded`: Boolean. Whether the submission is fully graded.
  - `isGradingPublished`: Boolean. Whether the grading is published.
  - `group`: Boolean. Only the groups under the grader should be returned.
  - `groupName`: String. Group name.
  - `name`: String. User name.
  - `username`: String. User username.
  - `type`: String. Assessment Config type.
  - `isManuallyGraded`: Boolean. Whether the assessment is manually graded.
  """
  operation(:index,
    summary: "Get submissions to grade, with the current user as grader",
    description:
      "Supports filtering and pagination via query parameters (pageSize, offset, " <>
        "title, status, group, groupName, name, username, type, etc.).",
    parameters: [
      course_id: [in: :path, type: :integer, required: true, description: "Course ID"],
      group: [in: :query, type: :boolean, required: false, description: "Only the grader's group"],
      pageSize: [
        in: :query,
        type: :integer,
        required: false,
        description: "Page size (default 10)"
      ],
      offset: [in: :query, type: :integer, required: false, description: "Offset (default 0)"]
    ],
    responses: [
      ok: {"Grading summaries", "application/json", %Schema{type: :object}},
      unauthorized: ErrorResponses.unauthorised(),
      forbidden: ErrorResponses.forbidden()
    ]
  )

  def index(conn, %{"group" => group} = params)
      when group in ["true", "false"] do
    course_reg = conn.assigns[:course_reg]

    boolean_params = [:is_fully_graded, :group, :is_manually_graded]
    int_params = [:page_size, :offset]

    # Convert string keys to atoms and parse values
    params =
      params
      |> to_snake_case_atom_keys()
      |> Map.put_new(:page_size, "10")
      |> Map.put_new(:offset, "0")

    filtered_boolean_params =
      params
      |> Map.take(boolean_params)
      |> Map.keys()

    params =
      params
      |> process_map_booleans(filtered_boolean_params)
      |> process_map_integers(int_params)
      |> Assessments.parse_sort_direction()
      |> Assessments.parse_sort_by()

    case Assessments.submissions_by_grader_for_index(course_reg, params) do
      {:ok, view_model} ->
        conn
        |> put_status(:ok)
        |> put_resp_content_type("application/json")
        |> render("gradingsummaries.json", view_model)
    end
  end

  def index(conn, _) do
    index(conn, %{"group" => "false"})
  end

  operation(:index_all_submissions,
    summary: "Get all submissions to grade (unpaginated)",
    parameters: [
      course_id: [in: :path, type: :integer, required: true, description: "Course ID"]
    ],
    responses: [
      ok: {"Grading summaries", "application/json", %Schema{type: :object}},
      unauthorized: ErrorResponses.unauthorised(),
      forbidden: ErrorResponses.forbidden()
    ]
  )

  def index_all_submissions(conn, _) do
    index(
      conn,
      %{
        "group" => "false",
        "pageSize" => "100000000000",
        "offset" => "0"
      }
    )
  end

  operation(:show,
    summary: "Get the answers of a submission to grade",
    parameters: [
      course_id: [in: :path, type: :integer, required: true, description: "Course ID"],
      submissionid: [in: :path, type: :integer, required: true, description: "Submission ID"]
    ],
    responses: [
      ok: {"Submission answers", "application/json", %Schema{type: :object}},
      bad_request: ErrorResponses.bad_request(),
      unauthorized: ErrorResponses.unauthorised(),
      forbidden: ErrorResponses.forbidden(),
      not_found: ErrorResponses.not_found()
    ]
  )

  def show(conn, %{"submissionid" => submission_id}) when is_ecto_id(submission_id) do
    case Assessments.get_answers_in_submission(submission_id) do
      {:ok, {answers, assessment}} ->
        case Courses.get_course_config(assessment.course_id) do
          {:ok, course} ->
            render(conn, "show.json", course: course, answers: answers, assessment: assessment)

          {:error, {status, message}} ->
            conn
            |> put_status(status)
            |> text(message)
        end

      {:error, {status, message}} ->
        conn
        |> put_status(status)
        |> text(message)
    end
  end

  operation(:update,
    summary: "Update the grading of an answer in a submission",
    parameters: [
      course_id: [in: :path, type: :integer, required: true, description: "Course ID"],
      submissionid: [in: :path, type: :integer, required: true, description: "Submission ID"],
      questionid: [in: :path, type: :integer, required: true, description: "Question ID"]
    ],
    request_body:
      {"The grading to apply", "application/json", CadetWeb.Schemas.UpdateGradingRequest},
    responses: [
      ok: {"Grading updated", "text/plain", %Schema{type: :string}},
      bad_request: ErrorResponses.bad_request(),
      unauthorized: ErrorResponses.unauthorised(),
      forbidden: ErrorResponses.forbidden()
    ]
  )

  def update(
        conn,
        %{
          "submissionid" => submission_id,
          "questionid" => question_id,
          "grading" => raw_grading
        }
      )
      when is_ecto_id(submission_id) and is_ecto_id(question_id) do
    course_reg = conn.assigns[:course_reg]

    grading = raw_grading |> snake_casify_string_keys()

    case Assessments.update_grading_info(
           %{submission_id: submission_id, question_id: question_id},
           grading,
           course_reg
         ) do
      {:ok, _} ->
        text(conn, "OK")

      {:error, {status, message}} ->
        conn
        |> put_status(status)
        |> text(message)
    end
  end

  def update(conn, _params) do
    conn
    |> put_status(:bad_request)
    |> text("Missing parameter")
  end

  operation(:unsubmit,
    summary: "Unsubmit a submission (avenger only)",
    parameters: [
      course_id: [in: :path, type: :integer, required: true, description: "Course ID"],
      submissionid: [in: :path, type: :integer, required: true, description: "Submission ID"]
    ],
    responses: [
      ok: {"Submission unsubmitted", "text/plain", %Schema{type: :string}},
      bad_request: ErrorResponses.bad_request(),
      unauthorized: ErrorResponses.unauthorised(),
      forbidden: ErrorResponses.forbidden(),
      not_found: ErrorResponses.not_found()
    ]
  )

  def unsubmit(conn, %{"submissionid" => submission_id}) when is_ecto_id(submission_id) do
    course_reg = conn.assigns[:course_reg]

    case Assessments.unsubmit_submission(submission_id, course_reg) do
      {:ok, nil} ->
        text(conn, "OK")

      {:error, {status, message}} ->
        conn
        |> put_status(status)
        |> text(message)
    end
  end

  operation(:unpublish_grades,
    summary: "Unpublish the grades of a submission",
    parameters: [
      course_id: [in: :path, type: :integer, required: true, description: "Course ID"],
      submissionid: [in: :path, type: :integer, required: true, description: "Submission ID"]
    ],
    responses: [
      ok: {"Grades unpublished", "text/plain", %Schema{type: :string}},
      unauthorized: ErrorResponses.unauthorised(),
      forbidden: ErrorResponses.forbidden()
    ]
  )

  def unpublish_grades(conn, %{"submissionid" => submission_id}) when is_ecto_id(submission_id) do
    course_reg = conn.assigns[:course_reg]

    case Assessments.unpublish_grading(submission_id, course_reg) do
      {:ok, nil} ->
        text(conn, "OK")

      {:error, {status, message}} ->
        conn
        |> put_status(status)
        |> text(message)
    end
  end

  operation(:publish_grades,
    summary: "Publish the grades of a submission",
    parameters: [
      course_id: [in: :path, type: :integer, required: true, description: "Course ID"],
      submissionid: [in: :path, type: :integer, required: true, description: "Submission ID"]
    ],
    responses: [
      ok: {"Grades published", "text/plain", %Schema{type: :string}},
      unauthorized: ErrorResponses.unauthorised(),
      forbidden: ErrorResponses.forbidden()
    ]
  )

  def publish_grades(conn, %{"submissionid" => submission_id}) when is_ecto_id(submission_id) do
    course_reg = conn.assigns[:course_reg]

    case Assessments.publish_grading(submission_id, course_reg) do
      {:ok, nil} ->
        text(conn, "OK")

      {:error, {status, message}} ->
        conn
        |> put_status(status)
        |> text(message)
    end
  end

  operation(:publish_all_grades,
    summary: "Publish the grades of all submissions for an assessment",
    parameters: [
      course_id: [in: :path, type: :integer, required: true, description: "Course ID"],
      assessmentid: [in: :path, type: :integer, required: true, description: "Assessment ID"]
    ],
    responses: [
      ok: {"Grades published", "text/plain", %Schema{type: :string}},
      unauthorized: ErrorResponses.unauthorised(),
      forbidden: ErrorResponses.forbidden()
    ]
  )

  def publish_all_grades(conn, %{"assessmentid" => assessment_id})
      when is_ecto_id(assessment_id) do
    course_reg = conn.assigns[:course_reg]

    case Assessments.publish_all_graded(course_reg, assessment_id) do
      {:ok, nil} ->
        text(conn, "OK")

      {:error, {status, message}} ->
        conn
        |> put_status(status)
        |> text(message)
    end
  end

  operation(:unpublish_all_grades,
    summary: "Unpublish the grades of all submissions for an assessment",
    parameters: [
      course_id: [in: :path, type: :integer, required: true, description: "Course ID"],
      assessmentid: [in: :path, type: :integer, required: true, description: "Assessment ID"]
    ],
    responses: [
      ok: {"Grades unpublished", "text/plain", %Schema{type: :string}},
      unauthorized: ErrorResponses.unauthorised(),
      forbidden: ErrorResponses.forbidden()
    ]
  )

  def unpublish_all_grades(conn, %{"assessmentid" => assessment_id})
      when is_ecto_id(assessment_id) do
    course_reg = conn.assigns[:course_reg]

    case Assessments.unpublish_all(course_reg, assessment_id) do
      {:ok, nil} ->
        text(conn, "OK")

      {:error, {status, message}} ->
        conn
        |> put_status(status)
        |> text(message)
    end
  end

  operation(:autograde_submission,
    summary: "Force re-autograding of an entire submission",
    parameters: [
      course_id: [in: :path, type: :integer, required: true, description: "Course ID"],
      submissionid: [in: :path, type: :integer, required: true, description: "Submission ID"]
    ],
    responses: [
      no_content: "Autograding started",
      bad_request: ErrorResponses.bad_request(),
      unauthorized: ErrorResponses.unauthorised(),
      forbidden: ErrorResponses.forbidden(),
      not_found: ErrorResponses.not_found()
    ]
  )

  def autograde_submission(conn, %{"submissionid" => submission_id}) do
    course_reg = conn.assigns[:course_reg]

    case Assessments.force_regrade_submission(submission_id, course_reg) do
      {:ok, nil} ->
        send_resp(conn, :no_content, "")

      {:error, {status, message}} ->
        conn
        |> put_status(status)
        |> text(message)
    end
  end

  operation(:autograde_answer,
    summary: "Force re-autograding of a single answer in a submission",
    parameters: [
      course_id: [in: :path, type: :integer, required: true, description: "Course ID"],
      submissionid: [in: :path, type: :integer, required: true, description: "Submission ID"],
      questionid: [in: :path, type: :integer, required: true, description: "Question ID"]
    ],
    responses: [
      no_content: "Autograding started",
      bad_request: ErrorResponses.bad_request(),
      unauthorized: ErrorResponses.unauthorised(),
      forbidden: ErrorResponses.forbidden(),
      not_found: ErrorResponses.not_found()
    ]
  )

  def autograde_answer(conn, %{"submissionid" => submission_id, "questionid" => question_id}) do
    course_reg = conn.assigns[:course_reg]

    case Assessments.force_regrade_answer(submission_id, question_id, course_reg) do
      {:ok, nil} ->
        send_resp(conn, :no_content, "")

      {:error, {status, message}} ->
        conn
        |> put_status(status)
        |> text(message)
    end
  end

  operation(:grading_summary,
    summary: "Get the group grading summary for the course",
    parameters: [
      course_id: [in: :path, type: :integer, required: true, description: "Course ID"]
    ],
    responses: [
      ok: {"Grading summary", "application/json", %Schema{type: :object}},
      unauthorized: ErrorResponses.unauthorised(),
      forbidden: ErrorResponses.forbidden()
    ]
  )

  def grading_summary(conn, %{"course_id" => course_id}) do
    case Assessments.get_group_grading_summary(course_id) do
      {:ok, cols, summary} ->
        render(conn, "grading_summary.json", cols: cols, summary: summary)
    end
  end
end
