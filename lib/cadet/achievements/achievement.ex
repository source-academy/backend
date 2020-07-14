defmodule Cadet.Achievements.Achievement do
  @moduledoc """
  The Achievement entity stores metadata of a students' assessment
  """
  use Cadet, :model

  alias Cadet.Achievements.{AchievementAbility, AchievementGoal}

  schema "achievements" do
    field(:inferencer_id, :integer)
    field(:title, :string)
    field(:ability, AchievementAbility)
    field(:background_image_url, :string)

    field(:open_at, :utc_datetime)
    field(:close_at, :utc_datetime)
    field(:is_task, :boolean)
    field(:prerequisite_ids, {:array, :integer})
    field(:position, :integer, default: 0)

    field(:modal_image_url, :string)
    field(:description, :string)
    field(:completion_text, :string)

    has_many(:goals, AchievementGoal)

    timestamps()
  end

  @required_fields ~w(title ability exp is_task position)a
  @optional_fields ~w(background_image_url open_at close_at prerequisite_ids
    modal_image_url description completion_text)a

  def changeset(achievement, params) do
    params =
      params
      |> convert_date(:open_at)
      |> convert_date(:close_at)

    achievement
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
