defmodule CadetWeb.AdminAssessmentsController do
  use CadetWeb, :controller
  use OpenApiSpex.ControllerSpecs

  import Ecto.Query, only: [where: 2]
  import Cadet.Updater.XMLParser, only: [parse_xml: 4]

  alias Cadet.Assessments.{Question, Assessment}
  alias Cadet.{Assessments, Repo}
  alias Cadet.Accounts.CourseRegistration
  alias CadetWeb.ApiSpec.ErrorResponses
  alias CadetWeb.Schemas
  alias OpenApiSpex.Schema

  tags(["Assessments"])
  security([%{"JWT" => []}])

  operation(:index,
    summary: "Get the assessment overviews for a specific user",
    parameters: [
      course_id: [in: :path, type: :integer, required: true, description: "Course ID"],
      course_reg_id: [in: :path, type: :integer, required: true, description: "Course reg ID"]
    ],
    responses: [
      ok:
        {"List of assessments", "application/json",
         %Schema{type: :array, items: Schemas.AssessmentOverview}},
      unauthorized: ErrorResponses.unauthorised(),
      forbidden: ErrorResponses.forbidden()
    ]
  )

  def index(conn, %{"course_reg_id" => course_reg_id}) do
    course_reg = Repo.get(CourseRegistration, course_reg_id)
    {:ok, assessments} = Assessments.all_assessments(course_reg)
    assessments = Assessments.format_all_assessments(assessments)
    render(conn, "index.json", assessments: assessments)
  end

  operation(:get_assessment,
    summary: "Get an assessment (with questions and answers) as seen by a specific user",
    parameters: [
      course_id: [in: :path, type: :integer, required: true, description: "Course ID"],
      course_reg_id: [in: :path, type: :integer, required: true, description: "Course reg ID"],
      assessmentid: [in: :path, type: :integer, required: true, description: "Assessment ID"]
    ],
    responses: [
      ok: {"The assessment", "application/json", Schemas.Assessment},
      bad_request: ErrorResponses.bad_request(),
      unauthorized: ErrorResponses.unauthorised(),
      forbidden: ErrorResponses.forbidden()
    ]
  )

  def get_assessment(conn, %{"course_reg_id" => course_reg_id, "assessmentid" => assessment_id})
      when is_ecto_id(assessment_id) do
    course_reg = Repo.get(CourseRegistration, course_reg_id)

    case Assessments.assessment_with_questions_and_answers(assessment_id, course_reg) do
      {:ok, assessment} -> render(conn, "show.json", assessment: assessment)
      {:error, {status, message}} -> send_resp(conn, status, message)
    end
  end

  operation(:create,
    summary: "Create or update an assessment from an XML file",
    parameters: [
      course_id: [in: :path, type: :integer, required: true, description: "Course ID"]
    ],
    request_body:
      {"The assessment XML and options", "multipart/form-data", Schemas.CreateAssessmentRequest},
    responses: [
      ok: {"Assessment created or updated", "text/plain", %Schema{type: :string}},
      bad_request: ErrorResponses.bad_request(),
      unauthorized: ErrorResponses.unauthorised(),
      forbidden: ErrorResponses.forbidden()
    ]
  )

  def create(conn, %{
        "course_id" => course_id,
        "assessment" => assessment,
        "forceUpdate" => force_update,
        "assessmentConfigId" => assessment_config_id
      }) do
    file =
      assessment["file"].path
      |> File.read!()

    result =
      case force_update do
        "true" -> parse_xml(file, course_id, assessment_config_id, true)
        "false" -> parse_xml(file, course_id, assessment_config_id, false)
      end

    case result do
      :ok ->
        if force_update == "true" do
          text(conn, "Force update OK")
        else
          text(conn, "OK")
        end

      {:ok, warning_message} ->
        text(conn, warning_message)

      {:error, {status, message}} ->
        conn
        |> put_status(status)
        |> text(message)
    end
  end

  operation(:delete,
    summary: "Delete an assessment",
    parameters: [
      course_id: [in: :path, type: :integer, required: true, description: "Course ID"],
      assessmentid: [in: :path, type: :integer, required: true, description: "Assessment ID"]
    ],
    responses: [
      ok: {"Assessment deleted", "text/plain", %Schema{type: :string}},
      unauthorized: ErrorResponses.unauthorised(),
      forbidden: ErrorResponses.forbidden()
    ]
  )

  def delete(conn, %{"course_id" => course_id, "assessmentid" => assessment_id}) do
    with {:same_course, true} <- {:same_course, is_same_course(course_id, assessment_id)},
         {:ok, _} <- Assessments.delete_assessment(assessment_id) do
      text(conn, "OK")
    else
      {:same_course, false} ->
        conn
        |> put_status(403)
        |> text("User not allow to delete assessments from another course")

      {:error, {status, message}} ->
        conn
        |> put_status(status)
        |> text(message)
    end
  end

  operation(:update,
    summary: "Update an assessment's dates and settings",
    parameters: [
      course_id: [in: :path, type: :integer, required: true, description: "Course ID"],
      assessmentid: [in: :path, type: :integer, required: true, description: "Assessment ID"]
    ],
    request_body:
      {"The assessment settings to update", "application/json", Schemas.UpdateAssessmentRequest},
    responses: [
      ok: {"Assessment updated", "text/plain", %Schema{type: :string}},
      bad_request: ErrorResponses.bad_request(),
      unauthorized: ErrorResponses.unauthorised(),
      forbidden: ErrorResponses.forbidden()
    ]
  )

  def update(conn, params = %{"assessmentid" => assessment_id}) when is_ecto_id(assessment_id) do
    open_at = params |> Map.get("openAt")
    close_at = params |> Map.get("closeAt")
    is_published = params |> Map.get("isPublished")
    max_team_size = params |> Map.get("maxTeamSize")
    has_token_counter = params |> Map.get("hasTokenCounter")
    has_voting_features = params |> Map.get("hasVotingFeatures")
    is_autosave_enabled = params |> Map.get("isAutosaveEnabled")
    assign_entries_for_voting = params |> Map.get("assignEntriesForVoting")

    updated_assessment =
      if is_nil(is_published) do
        %{}
      else
        %{:is_published => is_published}
      end

    updated_assessment =
      if is_nil(max_team_size) do
        updated_assessment
      else
        Map.put(updated_assessment, :max_team_size, max_team_size)
      end

    updated_assessment =
      if is_nil(has_token_counter) do
        updated_assessment
      else
        Map.put(updated_assessment, :has_token_counter, has_token_counter)
      end

    updated_assessment =
      if is_nil(has_voting_features) do
        updated_assessment
      else
        Map.put(updated_assessment, :has_voting_features, has_voting_features)
      end

    updated_assessment =
      if is_nil(is_autosave_enabled) do
        updated_assessment
      else
        Map.put(updated_assessment, :is_autosave_enabled, is_autosave_enabled)
      end

    is_reassigning_voting =
      if is_nil(assign_entries_for_voting) do
        false
      else
        assign_entries_for_voting
      end

    with {:ok, assessment} <- check_dates(open_at, close_at, updated_assessment),
         {:ok, _nil} <- Assessments.update_assessment(assessment_id, assessment),
         {:ok, _nil} <- Assessments.reassign_voting(assessment_id, is_reassigning_voting) do
      text(conn, "OK")
    else
      {:error, {status, message}} ->
        conn
        |> put_status(status)
        |> text(message)
    end
  end

  operation(:calculate_contest_score,
    summary: "Calculate relative contest scores for an assessment's voting question",
    parameters: [
      course_id: [in: :path, type: :integer, required: true, description: "Course ID"],
      assessmentid: [in: :path, type: :integer, required: true, description: "Assessment ID"]
    ],
    responses: [
      ok: {"Scores calculated", "text/plain", %Schema{type: :string}},
      unauthorized: ErrorResponses.unauthorised(),
      forbidden: ErrorResponses.forbidden()
    ]
  )

  def calculate_contest_score(conn, %{"assessmentid" => assessment_id, "course_id" => _course_id}) do
    voting_questions =
      Question
      |> where(type: :voting)
      |> where(assessment_id: ^assessment_id)
      |> Repo.one()

    if voting_questions do
      Assessments.compute_relative_score(voting_questions.id)
      text(conn, "Contest scores calculated")
    else
      text(conn, "No voting questions found for the given assessment")
    end
  end

  operation(:dispatch_contest_xp,
    summary: "Dispatch XP to the winning contest entries of an assessment",
    parameters: [
      course_id: [in: :path, type: :integer, required: true, description: "Course ID"],
      assessmentid: [in: :path, type: :integer, required: true, description: "Assessment ID"]
    ],
    responses: [
      ok: {"XP dispatched", "text/plain", %Schema{type: :string}},
      unauthorized: ErrorResponses.unauthorised(),
      forbidden: ErrorResponses.forbidden()
    ]
  )

  def dispatch_contest_xp(conn, %{"assessmentid" => assessment_id, "course_id" => _course_id}) do
    voting_questions =
      Question
      |> where(type: :voting)
      |> where(assessment_id: ^assessment_id)
      |> Repo.one()

    if voting_questions do
      Assessments.assign_winning_contest_entries_xp(voting_questions.id)

      text(conn, "XP Dispatched")
    else
      text(conn, "No voting questions found for the given assessment")
    end
  end

  defp check_dates(open_at, close_at, assessment) do
    if is_nil(open_at) and is_nil(close_at) do
      {:ok, assessment}
    else
      formatted_open_date = elem(DateTime.from_iso8601(open_at), 1)
      formatted_close_date = elem(DateTime.from_iso8601(close_at), 1)

      if DateTime.compare(formatted_close_date, formatted_open_date) == :lt do
        {:error, {:bad_request, "New end date should occur after new opening date"}}
      else
        assessment = Map.put(assessment, :open_at, formatted_open_date)
        assessment = Map.put(assessment, :close_at, formatted_close_date)
        {:ok, assessment}
      end
    end
  end

  defp is_same_course(course_id, assessment_id) do
    Assessment
    |> where(id: ^assessment_id)
    |> where(course_id: ^course_id)
    |> Repo.exists?()
  end
end
