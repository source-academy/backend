defmodule Cadet.Assessments.Assessment do
  @moduledoc """
  The Assessment entity stores metadata of a students' assessment
  (mission, sidequest, path, and contest)
  """
  use Cadet, :model
  use Arc.Ecto.Schema

  alias Cadet.Repo
  alias Cadet.Assessments.{AssessmentAccess, Question, SubmissionStatus, Upload}
  alias Cadet.Courses.{Course, AssessmentConfig}

  @type t :: %__MODULE__{}

  schema "assessments" do
    field(:access, AssessmentAccess, virtual: true, default: :public)
    field(:max_xp, :integer, virtual: true)
    field(:xp, :integer, virtual: true, default: 0)
    field(:user_status, SubmissionStatus, virtual: true)
    field(:grading_status, :string, virtual: true)
    field(:question_count, :integer, virtual: true)
    field(:graded_count, :integer, virtual: true)
    field(:is_grading_published, :boolean, virtual: true)
    field(:title, :string)
    field(:is_published, :boolean, default: false)
    field(:summary_short, :string)
    field(:summary_long, :string)
    field(:open_at, :utc_datetime_usec)
    field(:close_at, :utc_datetime_usec)
    field(:cover_picture, :string)
    field(:mission_pdf, Upload.Type)
    field(:number, :string)
    field(:story, :string)
    field(:reading, :string)
    field(:password, :string, default: nil)
    field(:max_team_size, :integer, default: 1)
    field(:has_token_counter, :boolean, default: false)
    field(:has_voting_features, :boolean, default: false)
    field(:llm_assessment_prompt, :string, default: nil)

    belongs_to(:config, AssessmentConfig)
    belongs_to(:course, Course)

    has_many(:questions, Question, on_delete: :delete_all)
    timestamps()
  end

  @required_fields ~w(title open_at close_at number course_id config_id max_team_size)a
  @optional_fields ~w(reading summary_short summary_long
    is_published story cover_picture access password has_token_counter has_voting_features llm_assessment_prompt)a
  @optional_file_fields ~w(mission_pdf)a

  def changeset(assessment, params) do
    params =
      params
      |> convert_date(:open_at)
      |> convert_date(:close_at)

    assessment
    |> cast_attachments(params, @optional_file_fields)
    |> cast(params, @required_fields ++ @optional_fields)
    |> validate_required(@required_fields)
    |> add_belongs_to_id_from_model([:config, :course], params)
    |> foreign_key_constraint(:config_id)
    |> foreign_key_constraint(:course_id)
    |> unique_constraint([:number, :course_id])
    |> validate_config_course
    |> validate_open_close_date
    |> validate_number(:max_team_size, greater_than_or_equal_to: 1)
  end

  defp validate_config_course(changeset) do
    config_id = get_field(changeset, :config_id)
    course_id = get_field(changeset, :course_id)

    case Repo.get(AssessmentConfig, config_id) do
      nil ->
        add_error(changeset, :config, "does not exist")

      config ->
        if config.course_id == course_id do
          changeset
        else
          add_error(changeset, :config, "does not belong to the same course as this assessment")
        end
    end
  end

  defp validate_open_close_date(changeset) do
    validate_change(changeset, :open_at, fn :open_at, open_at ->
      if Timex.before?(open_at, get_field(changeset, :close_at)) do
        []
      else
        [open_at: "Open date must be before close date"]
      end
    end)
  end
end
