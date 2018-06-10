defmodule Cadet.Assessments.Mission do
  @moduledoc """
  The Mission entity stores metadata of a students' assessment
  (mission, sidequest, path, and contest)
  """
  use Cadet, :model
  use Arc.Ecto.Schema

  alias Cadet.Assessments.Category
  alias Cadet.Assessments.Image

  schema "missions" do
    field :name, :string
    field :is_published, :boolean, default: false
    field(:order, :string)
    field(:category, Category)
    field(:title, :string)
    field(:summary_short, :string)
    field(:summary_long, :string)
    field(:open_at, Timex.Ecto.DateTime)
    field(:close_at, Timex.Ecto.DateTime)
    field :max_xp, :integer, default: 0
    field :priority, :integer, default: 0
    field(:cover_picture, Image.Type)
    has_many :questions, Question, on_delete: :delete_all
    timestamps()
  end

  @required_fields ~w(name order category title open_at close_at)a
  @optional_fields ~w(summary_short summary_long is_published max_xp priority)a
  @optional_file_fields ~w(cover_url)

  def changeset(mission, params) do
    mission
    |> cast(params, @required_fields ++ @optional_fields)
    |> validate_required(@required_fields)
    |> validate_number(:max_xp, greater_than_or_equal_to: 0)
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
