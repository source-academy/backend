defmodule CadetWeb.AssessmentsController do
  use CadetWeb, :controller

  use PhoenixSwagger

  alias Cadet.Assessments
  import Cadet.Updater.XMLParser, only: [parse_xml: 2]

  def submit(conn, %{"assessmentid" => assessment_id}) when is_ecto_id(assessment_id) do
    case Assessments.finalise_submission(assessment_id, conn.assigns.current_user) do
      {:ok, _nil} ->
        text(conn, "OK")

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

  def show(conn, params = %{"id" => assessment_id}) when is_ecto_id(assessment_id) do
    user = conn.assigns[:current_user]
    password = params |> Map.get("password")

    case Assessments.assessment_with_questions_and_answers(assessment_id, user, password) do
      {:ok, assessment} -> render(conn, "show.json", assessment: assessment)
      {:error, {status, message}} -> send_resp(conn, status, message)
    end
  end

  def publish(conn, %{"id" => id, "togglePublishTo" => toggle_publish_to}) do
    result =
      Assessments.toggle_publish_assessment(conn.assigns.current_user, id, toggle_publish_to)

    case result do
      {:ok, _nil} ->
        send_resp(conn, 200, "OK")

      {:error, {status, message}} ->
        conn
        |> put_status(status)
        |> text(message)
    end
  end

  def update(conn, %{"id" => id, "closeAt" => close_at, "openAt" => open_at}) do
    formatted_close_date = elem(DateTime.from_iso8601(close_at), 1)
    formatted_open_date = elem(DateTime.from_iso8601(open_at), 1)

    result =
      Assessments.change_dates_assessment(
        conn.assigns.current_user,
        id,
        formatted_close_date,
        formatted_open_date
      )

    case result do
      {:ok, _nil} ->
        send_resp(conn, 200, "OK")

      {:error, {status, message}} ->
        conn
        |> put_status(status)
        |> text(message)
    end
  end

  def delete(conn, %{"id" => id}) do
    result = Assessments.delete_assessment(conn.assigns.current_user, id)

    case result do
      {:ok, _nil} ->
        send_resp(conn, 200, "OK")

      {:error, {status, message}} ->
        conn
        |> put_status(status)
        |> text(message)
    end
  end

  def create(conn, %{"assessment" => assessment, "forceUpdate" => force_update}) do
    role = conn.assigns[:current_user].role

    if role == :student do
      send_resp(conn, :forbidden, "User not allowed to create")
    else
      file =
        assessment["file"].path
        |> File.read!()

      result =
        case force_update do
          "true" -> parse_xml(file, true)
          "false" -> parse_xml(file, false)
        end

      case result do
        :ok ->
          if force_update == "true" do
            send_resp(conn, 200, "Force Update OK")
          else
            send_resp(conn, 200, "OK")
          end

        {:ok, warning_message} ->
          send_resp(conn, 200, warning_message)

        {:error, {status, message}} ->
          send_resp(conn, status, message)
      end
    end
  end

  swagger_path :submit do
    post("/assessments/{assessmentId}/submit")
    summary("Finalise submission for an assessment")
    security([%{JWT: []}])

    parameters do
      assessmentId(:path, :integer, "submission id", required: true)
    end

    response(200, "OK")
    response(400, "Invalid parameters")
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
    post("/assessments/{assessmentId}")

    summary("Get information about one particular assessment.")

    security([%{JWT: []}])

    consumes("application/json")
    produces("application/json")

    parameters do
      assessmentId(:path, :integer, "assessment id", required: true)
      password(:body, :string, "password", required: false)
    end

    response(200, "OK", Schema.ref(:Assessment))
    response(400, "Missing parameter(s) or invalid assessmentId")
    response(401, "Unauthorised")
    response(403, "Password incorrect")
  end

  swagger_path :create do
    post("/assessments")

    summary("Creates a new assessment or updates an existing assessment")

    security([%{JWT: []}])

    parameters do
      assessment(:body, :file, "assessment to create or update", required: true)
      forceUpdate(:body, :boolean, "force update", required: true)
    end

    response(200, "OK")
    response(400, "XML parse error")
    response(403, "User not allowed to create")
  end

  swagger_path :delete do
    PhoenixSwagger.Path.delete("/assessments/:id")

    summary("Deletes an assessment")

    security([%{JWT: []}])

    parameters do
      assessmentId(:path, :integer, "assessment id", required: true)
    end

    response(200, "OK")
    response(403, "User is not permitted to delete")
  end

  swagger_path :publish do
    post("/assessments/publish/:id")

    summary("Toggles an assessment between published and unpublished")

    security([%{JWT: []}])

    parameters do
      assessmentId(:path, :integer, "assessment id", required: true)
      togglePublishTo(:body, :boolean, "toggles assessment publish state", required: true)
    end

    response(200, "OK")
    response(403, "User is not permitted to publish")
  end

  swagger_path :update do
    post("/assessments/update/:id")

    summary("Changes the open/close date of an assessment")

    security([%{JWT: []}])

    parameters do
      assessmentId(:path, :integer, "assessment id", required: true)
      closeAt(:body, :string, "open date", required: true)
      openAt(:body, :string, "close date", required: true)
    end

    response(200, "OK")
    response(401, "Assessment is already opened")
    response(403, "User is not permitted to edit")
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
              :string,
              "one of 'not_attempted/attempting/attempted/submitted' indicating whether the assessment has been attempted by the current user",
              required: true
            )

            gradingStatus(
              :string,
              "'excluded' if the assessment does not yet require grading, otherwise one of 'none/grading/graded' indicating the extent to which it has been fully graded",
              required: true
            )

            maxGrade(
              :integer,
              "The maximum Grade for this assessment",
              required: true
            )

            maxXp(
              :integer,
              "The maximum xp for this assessment",
              required: true
            )

            xp(:integer, "The xp earned for this assessment", required: true)

            grade(:integer, "The grade earned for this assessment", required: true)

            coverImage(:string, "The URL to the cover picture", required: true)

            private(:boolean, "Is this an private assessment?", required: true)

            isPublished(:boolean, "Is the assessment published?", required: true)
          end
        end,
      Assessment:
        swagger_schema do
          properties do
            id(:integer, "The assessment id", required: true)
            title(:string, "The title of the assessment", required: true)
            type(:string, "Either mission/sidequest/path/contest", required: true)

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
      Questions:
        swagger_schema do
          description("A list of questions")
          type(:array)
          items(Schema.ref(:Question))
        end,
      Question:
        swagger_schema do
          properties do
            id(:integer, "The question id", required: true)
            type(:string, "The question type (mcq/programming)", required: true)
            content(:string, "The question content", required: true)
            roomId(:string, "Chatkit room id.")

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
              "The library used for this question"
            )

            prepend(:string, "Prepend program for programming questions")

            template(:string, "Solution template for programming questions")

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
            comments(:string, "String of comments given for a student's answer", required: false)

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

            autogradingStatus(
              :string,
              "One of none/processing/success/failed"
            )

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
            type(:string, "One of public/hidden/private")
          end
        end,
      AutogradingResult:
        swagger_schema do
          properties do
            resultType(:string, "One of pass/fail/error")
            expected(:string)
            actual(:string)
          end
        end
    }
  end
end
