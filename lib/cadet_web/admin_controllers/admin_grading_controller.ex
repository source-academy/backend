defmodule CadetWeb.AdminGradingController do
  use CadetWeb, :controller
  use PhoenixSwagger

  alias Cadet.{Assessments, Courses}

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

  def grading_summary(conn, %{"course_id" => course_id}) do
    case Assessments.get_group_grading_summary(course_id) do
      {:ok, cols, summary} ->
        render(conn, "grading_summary.json", cols: cols, summary: summary)
    end
  end

  swagger_path :index do
    get("/courses/{course_id}/admin/grading")

    summary("Get a list of all submissions with current user as the grader")

    security([%{JWT: []}])

    produces("application/json")

    parameters do
      group(
        :query,
        :boolean,
        "Show only students in the grader's group when true",
        required: false
      )
    end

    response(200, "OK", Schema.ref(:Submissions))
    response(401, "Unauthorised")
    response(403, "Forbidden")
  end

  swagger_path :unsubmit do
    post("/courses/{course_id}/admin/grading/{submissionId}/unsubmit")
    summary("Unsubmit submission. Can only be done by the Avenger of a student")
    security([%{JWT: []}])

    parameters do
      submissionId(:path, :integer, "submission id", required: true)
    end

    response(200, "OK")
    response(400, "Invalid parameters")
    response(403, "Forbidden")
    response(404, "Submission not found")
  end

  swagger_path :autograde_submission do
    post("/courses/{course_id}/admin/grading/{submissionId}/autograde")
    summary("Force re-autograding of an entire submission")
    security([%{JWT: []}])

    parameters do
      submissionId(:path, :integer, "submission id", required: true)
    end

    response(204, "Successful request")
    response(400, "Invalid parameters or submission not submitted")
    response(403, "Forbidden")
    response(404, "Submission not found")
  end

  swagger_path :autograde_answer do
    post("/courses/{course_id}/admin/grading/{submissionId}/{questionId}/autograde")
    summary("Force re-autograding of a question in a submission")
    security([%{JWT: []}])

    parameters do
      submissionId(:path, :integer, "submission id", required: true)
      questionId(:path, :integer, "question id", required: true)
    end

    response(204, "Successful request")
    response(400, "Invalid parameters or submission not submitted")
    response(403, "Forbidden")
    response(404, "Answer not found")
  end

  swagger_path :show do
    get("/courses/{course_id}/admin/grading/{submissionId}")

    summary("Get information about a specific submission to be graded")

    security([%{JWT: []}])

    produces("application/json")

    parameters do
      submissionId(:path, :integer, "submission id", required: true)
    end

    response(200, "OK", Schema.ref(:GradingInfo))
    response(400, "Invalid or missing parameter(s) or submission and/or question not found")
    response(401, "Unauthorised")
    response(403, "Forbidden")
  end

  swagger_path :update do
    post("/courses/{course_id}/admin/grading/{submissionId}/{questionId}")

    summary("Update marks given to the answer of a particular question in a submission")

    security([%{JWT: []}])

    consumes("application/json")
    produces("application/json")

    parameters do
      submissionId(:path, :integer, "submission id", required: true)
      questionId(:path, :integer, "question id", required: true)
      grading(:body, Schema.ref(:Grading), "adjustments for a question", required: true)
    end

    response(200, "OK")
    response(400, "Invalid or missing parameter(s) or submission and/or question not found")
    response(401, "Unauthorised")
    response(403, "Forbidden")
  end

  swagger_path :grading_summary do
    get("/courses/{course_id}/admin/grading/summary")

    summary("Receives a summary of grading items done by this grader")

    security([%{JWT: []}])

    produces("application/json")

    response(200, "OK", Schema.array(:GradingSummary))
    response(400, "Invalid or missing parameter(s) or submission and/or question not found")
    response(401, "Unauthorised")
    response(403, "Forbidden")
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
            id(:integer, "Submission id", required: true)
            grade(:integer, "Grade given", required: true)
            xp(:integer, "XP earned", required: true)
            xpBonus(:integer, "Bonus XP for a given submission", required: true)
            xpAdjustment(:integer, "XP adjustment given", required: true)
            adjustment(:integer, "Grade adjustment given", required: true)

            status(
              Schema.ref(:AssessmentStatus),
              "One of 'not_attempted/attempting/attempted/submitted' indicating whether the assessment has been attempted by the current user",
              required: true
            )

            gradedCount(:integer, "Number of questions in this submission that have been graded",
              required: true
            )

            assessment(Schema.ref(:AssessmentInfo), "Assessment for which the submission is for",
              required: true
            )

            student(Schema.ref(:StudentInfo), "Student who created the submission",
              required: true
            )

            unsubmittedBy(Schema.ref(:GraderInfo))
            unsubmittedAt(:string, "Last unsubmitted at", format: "date-time", required: false)

            isGradingPublished(:boolean, "Whether the grading is published", required: true)
          end
        end,
      AssessmentInfo:
        swagger_schema do
          properties do
            id(:integer, "assessment id", required: true)

            config(Schema.ref(:AssessmentConfig), "Either mission/sidequest/path/contest",
              required: true
            )

            title(:string, "Mission title", required: true)

            maxGrade(
              :integer,
              "The max grade for this assessment",
              required: true
            )

            maxXp(
              :integer,
              "The max xp for this assessment",
              required: true
            )

            questionCount(:integer, "number of questions in this assessment", required: true)
          end
        end,
      StudentInfo:
        swagger_schema do
          properties do
            id(:integer, "student id", required: true)
            name(:string, "student name", required: true)
            username(:string, "student username", required: true)
            groupName(:string, "name of student's group")
            groupLeaderId(:integer, "user id of group leader")
          end
        end,
      GraderInfo:
        swagger_schema do
          properties do
            id(:integer, "grader id", required: true)
            name(:string, "grader name", required: true)
          end
        end,
      GradingInfo:
        swagger_schema do
          description(
            "A list of questions with submitted answers, solution and previous grading info " <>
              "if available"
          )

          type(:array)

          items(
            Schema.new do
              properties do
                question(Schema.ref(:Question), "Question", required: true)
                grade(Schema.ref(:Grade), "Grading information", required: true)
                student(Schema.ref(:StudentInfo), "Student", required: true)

                solution(
                  :string,
                  "the marking scheme and model solution to this question. Only available for programming questions",
                  required: true
                )

                maxGrade(
                  :integer,
                  "the max grade that can be given to this question",
                  required: true
                )

                maxXp(
                  :integer,
                  "the max xp that can be given to this question",
                  required: true
                )
              end
            end
          )
        end,
      GradingSummary:
        swagger_schema do
          description("Summary of grading items for current user as the grader")

          properties do
            groupName(:string, "Name of group this grader is in", required: true)
            leaderName(:string, "Name of group leader", required: true)
            submittedMissions(:integer, "Number of submitted missions", required: true)
            submittedSidequests(:integer, "Number of submitted sidequests", required: true)
            ungradedMissions(:integer, "Number of ungraded missions", required: true)
            ungradedSidequests(:integer, "Number of ungraded sidequests", required: true)
          end
        end,
      Grade:
        swagger_schema do
          properties do
            grade(:integer, "Grade awarded by autograder")
            xp(:integer, "XP awarded by autograder")
            adjustment(:integer, "Grade adjustment given")
            xpAdjustment(:integer, "XP adjustment given", required: true)
            grader(Schema.ref(:GraderInfo))
            gradedAt(:string, "Last graded at", format: "date-time", required: false)
            comments(:string, "Comments given by grader")
          end
        end,
      Grading:
        swagger_schema do
          properties do
            grading(
              Schema.new do
                properties do
                  adjustment(:integer, "Grade adjustment given")
                  xpAdjustment(:integer, "XP adjustment given")
                  comments(:string, "Comments given by grader")
                end
              end
            )
          end
        end
    }
  end
end
