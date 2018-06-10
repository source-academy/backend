defmodule Cadet.Assessments.Mission do
  @moduledoc """
  The Mission entity stores metadata of a students' assessment
  (mission, sidequest, path, and contest)
  """
  use Cadet, :model
  use Arc.Ecto.Schema

  alias Cadet.Assessments.Category
  alias Cadet.Assessments.Image
  alias Cadet.Assessments.Question
  alias Cadet.Assessments.Upload

  schema "missions" do
    field(:title, :string)
    field(:is_published, :boolean, default: false)
    field(:category, Category)
    field(:summary_short, :string)
    field(:summary_long, :string)
    field(:open_at, Timex.Ecto.DateTime)
    field(:close_at, Timex.Ecto.DateTime)
    field(:xp, :integer, default: 0)
    field(:cover_picture, Image.Type)
    field(:mission_pdf, Upload.Type)
    has_many(:questions, Question, on_delete: :delete_all)
    timestamps()
  end

  @required_fields ~w(category title open_at close_at xp)a
  @optional_fields ~w(summary_short summary_long is_published xp)a
  @optional_file_fields ~w(cover_picture mission_pdf)a

  def changeset(mission, params) do
    params = params
      |> convert_date(:open_at)
      |> convert_date(:close_at)
    mission
    |> cast(params, @required_fields ++ @optional_fields)
    |> validate_required(@required_fields)
    |> validate_number(:xp, greater_than_or_equal_to: 0)
    |> cast_attachments(params, @optional_file_fields)
    |> validate_open_close_date
  end
end
