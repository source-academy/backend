defmodule Cadet.Assessments.Mission do
  @moduledoc """
  The Mission entity stores metadata of a students' assessment
  (mission, sidequest, path, and contest)
  """
  use Cadet, :model
  use Arc.Ecto.Schema

  alias Cadet.Assessments.Category
  alias Cadet.Assessments.Image
  alias Cadet.Assessments.Upload

  schema "missions" do
    field(:order, :string)
    field(:category, Category)
    field(:title, :string)
    field(:summary_short, :string)
    field(:summary_long, :string)
    field(:open_at, Timex.Ecto.DateTime)
    field(:close_at, Timex.Ecto.DateTime)
    field(:file, Upload.Type)
    field(:cover_picture, Image.Type)
    field(:max_xp, :integer)
  end

  @required_fields ~w(order category title open_at close_at max_xp)a
  @optional_fields ~w(summary_short summary_long)a
  @required_file_fields ~w(file)a
  @optional_file_fields ~w(cover_picture)a

  def changeset(mission, attrs \\ %{}) do
    mission
    |> cast(attrs, @required_fields ++ @optional_fields)
    |> cast_attachments(attrs, @required_file_fields ++ @optional_file_fields)
    |> validate_required(@required_fields ++ @required_file_fields)
    |> validate_number(:max_xp, greater_than_or_equal_to: 0)
  end
end
