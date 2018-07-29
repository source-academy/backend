defmodule CadetWeb.GradingController do
  use CadetWeb, :controller
  use PhoenixSwagger

  alias Cadet.Assessments

  def index(conn, _) do
    user = conn.assigns[:current_user]

    case Assessments.all_submissions_by_grader(user) do
      {:ok, submissions} ->
        render(conn, "index.json", submissions: submissions)

      {:error, {status, message}} ->
        conn
        |> put_status(status)
        |> text(message)
    end
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
        params = %{
          "submissionid" => submission_id,
          "questionid" => question_id
        }
      )
      when is_ecto_id(submission_id) and is_ecto_id(question_id) do
    user = conn.assigns[:current_user]

    case Assessments.update_grading_info(
           %{submission_id: submission_id, question_id: question_id},
           params["grading"],
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

  swagger_path :index do
    get("/grading")

    summary("Get a list of all submissions with current user as the grader. ")

    security([%{JWT: []}])

    produces("application/json")

    response(200, "OK", Schema.ref(:Submissions))
    response(401, "Unauthorised")
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

    summary(
      "Update comment and/or marks given to the answer of a particular querstion in a submission"
    )

    security([%{JWT: []}])

    consumes("application/json")
    produces("application/json")

    parameters do
      submissionId(:path, :integer, "submission id", required: true)
      questionId(:path, :integer, "question id", required: true)
      grading(:body, Schema.ref(:Grade), "comment given for a question", required: true)
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
            submissionId(:integer, "submission id", required: true)
            grade(:integer, "grade given")
            adjustment(:integer, "adjustment given")
            assessment(Schema.ref(:AssessmentInfo))
            student(Schema.ref(:StudentInfo))
          end
        end,
      AssessmentInfo:
        swagger_schema do
          properties do
            id(:integer, "assessment id", required: true)
            type(:string, "Either mission/sidequest/path/contest", required: true)

            max_grade(
              :integer,
              "The max grade for this assessment",
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
      GradingInfo:
        swagger_schema do
          description(
            "A list of questions with submitted answers and previous grading info if available"
          )

          type(:array)

          items(
            Schema.new do
              properties do
                question(Schema.ref(:Question))
                grade(Schema.ref(:Grade))

                max_grade(
                  :integer,
                  "the max grade that can be given to this question",
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
            comment(:string, "comment given")
            adjustment(:integer, "adjustment given")
          end
        end
    }
  end
end
