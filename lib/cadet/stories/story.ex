defmodule Cadet.Stories.Story do
  @moduledoc """
  The Story entity stores metadata of a story
  """
  use Cadet, :model

  alias Cadet.Courses.Course

  schema "stories" do
    field(:open_at, :utc_datetime_usec)
    field(:close_at, :utc_datetime_usec)
    field(:is_published, :boolean, default: false)
    field(:title, :string)
    field(:image_url, :string)
    field(:filenames, {:array, :string})

    belongs_to(:course, Course)

    timestamps()
  end

  @required_fields ~w(open_at close_at title filenames course_id)a
  @optional_fields ~w(is_published image_url)a

  def changeset(story, attrs \\ %{}) do
    story
    |> cast(attrs, @required_fields ++ @optional_fields)
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
