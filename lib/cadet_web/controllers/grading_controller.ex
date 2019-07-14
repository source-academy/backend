defmodule CadetWeb.GradingController do
  use CadetWeb, :controller
  use PhoenixSwagger

  alias Cadet.Assessments

  def index(conn, %{"group" => group}) when group in ["true", "false"] do
    user = conn.assigns[:current_user]

    group = String.to_atom(group)

    case Assessments.all_submissions_by_grader(user, group) do
      {:ok, submissions} ->
        render(conn, "index.json", submissions: submissions)

      {:error, {status, message}} ->
        conn
        |> put_status(status)
        |> text(message)
    end
  end

  def index(conn, _) do
    index(conn, %{"group" => "false"})
  end

  def show(conn, %{"submissionid" => submission_id}) when is_ecto_id(submission_id) do
    user = conn.assigns[:current_user]

    case Assessments.get_answers_in_submission(submission_id, user) do
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

  swagger_path :index do
    get("/grading")

    summary("Get a list of all submissions with current user as the grader.")

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
  end

  swagger_path :unsubmit do
    post("/grading/{submissionId}/unsubmit")
    summary("Unsubmit submission. Can only be done by the Avenger of a student.")
    security([%{JWT: []}])

    parameters do
      submissionId(:path, :integer, "submission id", required: true)
    end

    response(200, "OK")
    response(400, "Invalid parameters")
    response(403, "User not permitted to unsubmit assessment or assessment not open")
    response(404, "Submission not found")
  end

  swagger_path :show do
    get("/grading/{submissionId}")

    summary("Get information about a specific submission to be graded.")

    security([%{JWT: []}])

    produces("application/json")

    parameters do
      submissionId(:path, :integer, "submission id", required: true)
    end

    response(200, "OK", Schema.ref(:GradingInfo))
    response(400, "Invalid or missing parameter(s) or submission and/or question not found")
    response(401, "Unauthorised")
  end

  swagger_path :update do
    post("/grading/{submissionId}/{questionId}")

    summary("Update marks given to the answer of a particular querstion in a submission")

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
            id(:integer, "submission id", required: true)
            grade(:integer, "grade given")
            xp(:integer, "xp earned")
            xpBonus(:integer, "bonus xp for a given submission")
            xpAdjustment(:integer, "xp adjustment given")
            adjustment(:integer, "grade adjustment given")
            groupName(:string, "name of student's group")

            status(
              :string,
              "one of 'not_attempted/attempting/attempted/submitted' indicating whether the assessment has been attempted by the current user"
            )

            assessment(Schema.ref(:AssessmentInfo))
            student(Schema.ref(:StudentInfo))

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
            coverImage(:string, "The URL to the cover picture", required: true)

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
          end
        end,
      StudentInfo:
        swagger_schema do
          properties do
            id(:integer, "student id", required: true)
            name(:string, "student name", required: true)
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
                question(Schema.ref(:Question))
                grade(Schema.ref(:Grade))
                student(Schema.ref(:StudentInfo))

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
      Grade:
        swagger_schema do
          properties do
            grade(:integer, "Grade awarded by autograder")
            xp(:integer, "XP awarded by autograder")
            roomId(:string, "associated chatkit room id")
            adjustment(:integer, "grade adjustment given")
            xpAdjustment(:integer, "xp adjustment given")
            grader(Schema.ref(:GraderInfo))
            gradedAt(:string, "Last graded at", format: "date-time", required: false)
          end
        end,
      Grading:
        swagger_schema do
          properties do
            grading(
              Schema.new do
                properties do
                  adjustment(:integer, "grade adjustment given")
                  xpAdjustment(:integer, "xp adjustment given")
                end
              end
            )
          end
        end
    }
  end
end
