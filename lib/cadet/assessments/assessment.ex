defmodule Cadet.Assessments.Assessment do
  @moduledoc """
  The Assessment entity stores metadata of a students' assessment
  (mission, sidequest, path, and contest)
  """
  use Cadet, :model
  use Arc.Ecto.Schema
  alias Cadet.Assessments.{AssessmentType, Image, Question, SubmissionStatus, Upload}

  schema "assessments" do
    field(:max_grade, :integer, virtual: true)
    field(:user_status, SubmissionStatus, virtual: true)
    field(:title, :string)
    field(:is_published, :boolean, default: false)
    field(:type, AssessmentType)
    field(:summary_short, :string)
    field(:summary_long, :string)
    field(:open_at, Timex.Ecto.DateTime)
    field(:close_at, Timex.Ecto.DateTime)
    field(:cover_picture, Image.Type)
    field(:mission_pdf, Upload.Type)
    field(:number, :string)
    field(:story, :string)
    field(:reading, :string)

    has_many(:questions, Question, on_delete: :delete_all)
    timestamps()
  end

  @required_fields ~w(type title open_at close_at number)a
  @optional_fields ~w(reading summary_short summary_long is_published story)a
  @optional_file_fields ~w(cover_picture mission_pdf)a

  def changeset(assessment, params) do
    params =
      params
      |> convert_date(:open_at)
      |> convert_date(:close_at)

    assessment
    |> cast_attachments(params, @optional_file_fields)
    |> cast(params, @required_fields ++ @optional_fields)
    |> validate_required(@required_fields)
    |> validate_open_close_date
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
