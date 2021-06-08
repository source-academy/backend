defmodule Cadet.Assessments.Assessment do
  @moduledoc """
  The Assessment entity stores metadata of a students' assessment
  (mission, sidequest, path, and contest)
  """
  use Cadet, :model
  use Arc.Ecto.Schema

  alias Cadet.Repo
  alias Cadet.Assessments.{AssessmentAccess, Question, SubmissionStatus, Upload}
  alias Cadet.Courses.{Course, AssessmentTypes}

  # @assessment_types ~w(contest mission path practical sidequest)
  # def assessment_types, do: @assessment_types

  schema "assessments" do
    field(:access, AssessmentAccess, virtual: true, default: :public)
    field(:max_grade, :integer, virtual: true)
    field(:grade, :integer, virtual: true, default: 0)
    field(:max_xp, :integer, virtual: true)
    field(:xp, :integer, virtual: true, default: 0)
    field(:user_status, SubmissionStatus, virtual: true)
    field(:grading_status, :string, virtual: true)
    field(:question_count, :integer, virtual: true)
    field(:graded_count, :integer, virtual: true)
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

    belongs_to(:type, AssessmentTypes)
    belongs_to(:course, Course)

    has_many(:questions, Question, on_delete: :delete_all)
    timestamps()
  end

  @required_fields ~w(title open_at close_at number course_id type_id)a
  @optional_fields ~w(reading summary_short summary_long
    is_published story cover_picture access password)a
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
    |> validate_type_course
    |> validate_open_close_date
  end

  defp validate_type_course(changeset) do
    type_id = get_field(changeset, :type_id)
    course_id = get_field(changeset, :course_id)

    case Repo.get(AssessmentTypes, type_id) do
      nil -> add_error(changeset, :type, "does not exist")

      type -> if type.course_id == course_id do
        changeset
      else
        add_error(changeset, :type, "does not belong to the same course as this assessment")
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
