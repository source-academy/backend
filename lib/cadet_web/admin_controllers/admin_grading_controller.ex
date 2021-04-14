defmodule CadetWeb.AdminGradingController do
  use CadetWeb, :controller
  use PhoenixSwagger

  alias Cadet.Assessments

  def index(conn, %{"group" => group}) when group in ["true", "false"] do
    user = conn.assigns[:current_user]

    group = String.to_atom(group)

    case Assessments.all_submissions_by_grader_for_index(user, group) do
      {:ok, submissions} ->
        conn
        |> put_status(:ok)
        |> put_resp_content_type("application/json")
        |> text(submissions)
    end
  end

  def index(conn, _) do
    index(conn, %{"group" => "false"})
  end

  def show(conn, %{"submissionid" => submission_id}) when is_ecto_id(submission_id) do
    case Assessments.get_answers_in_submission(submission_id) do
      {:ok, answers} ->
        render(conn, "show.json", answers: answers)

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
    user = conn.assigns[:current_user]

    grading =
      if raw_grading["xpAdjustment"] do
        Map.put(raw_grading, "xp_adjustment", raw_grading["xpAdjustment"])
      else
        raw_grading
      end

    case Assessments.update_grading_info(
           %{submission_id: submission_id, question_id: question_id},
           grading,
           user
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
    user = conn.assigns[:current_user]

    case Assessments.unsubmit_submission(submission_id, user) do
      {:ok, nil} ->
        text(conn, "OK")

      {:error, {status, message}} ->
        conn
        |> put_status(status)
        |> text(message)
    end
  end

  def unsubmit(conn, _params) do
    conn
    |> put_status(:bad_request)
    |> text("Missing parameter")
  end

  def autograde_submission(conn, %{"submissionid" => submission_id}) do
    user = conn.assigns[:current_user]

    case Assessments.force_regrade_submission(submission_id, user) do
      {:ok, nil} ->
        send_resp(conn, :no_content, "")

      {:error, {status, message}} ->
        conn
        |> put_status(status)
        |> text(message)
    end
  end

  def autograde_answer(conn, %{"submissionid" => submission_id, "questionid" => question_id}) do
    user = conn.assigns[:current_user]

    case Assessments.force_regrade_answer(submission_id, question_id, user) do
      {:ok, nil} ->
        send_resp(conn, :no_content, "")

      {:error, {status, message}} ->
        conn
        |> put_status(status)
        |> text(message)
    end
  end

  def grading_summary(conn, _params) do
    case Assessments.get_group_grading_summary() do
      {:ok, summary} ->
        render(conn, "grading_summary.json", summary: summary)
    end
  end

  swagger_path :index do
    get("/admin/grading")

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
    post("/admin/grading/{submissionId}/unsubmit")
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
    post("/admin/grading/{submissionId}/autograde")
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
    post("/admin/grading/{submissionId}/{questionId}/autograde")
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
    get("/admin/grading/{submissionId}")

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
    post("/admin/grading/{submissionId}/{questionId}")

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
    get("/admin/grading/summary")

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
            xpBonus(:integer, "Bonus XP for a given submission")
            xpAdjustment(:integer, "XP adjustment given")
            adjustment(:integer, "Grade adjustment given")

            status(
              Schema.ref(:AssessmentStatus),
              "One of 'not_attempted/attempting/attempted/submitted' indicating whether the assessment has been attempted by the current user"
            )

            gradedCount(:integer, "Number of questions in this submission that have been graded",
              required: true
            )

            assessment(Schema.ref(:AssessmentInfo), "Assessment for which the submission is for", required: true)
            student(Schema.ref(:StudentInfo), "Student who created the submission", required: true)

            unsubmittedBy(Schema.ref(:GraderInfo))
            unsubmittedAt(:string, "Last unsubmitted at", format: "date-time", required: false)
          end
        end,
      AssessmentInfo:
        swagger_schema do
          properties do
            id(:integer, "assessment id", required: true)
            type(:string, "Either mission/sidequest/path/contest", required: true)
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
            groupName(:string, "Name of group this grader is in")
            leaderName(:string, "Name of group leader")
            submittedMissions(:integer, "Number of submitted missions")
            submittedSidequests(:integer, "Number of submitted sidequests")
            unsubmittedMissions(:integer, "Number of unsubmitted missions")
            unsubmittedSidequests(:integer, "Number of unsubmitted sidequests")
          end
        end,
      Grade:
        swagger_schema do
          properties do
            grade(:integer, "Grade awarded by autograder")
            xp(:integer, "XP awarded by autograder")
            adjustment(:integer, "Grade adjustment given")
            xpAdjustment(:integer, "XP adjustment given")
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
