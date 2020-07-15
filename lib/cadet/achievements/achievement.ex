defmodule Cadet.Achievements.Achievement do
  @moduledoc """
  The Achievement entity stores metadata of a students' assessment
  """
  use Cadet, :model

  alias Cadet.Achievements.{AchievementAbility, AchievementGoal, AchievementPrerequisite}

  schema "achievements" do
    field(:inferencer_id, :integer)
    field(:title, :string)
    field(:ability, AchievementAbility)
    field(:background_image_url, :string)

    field(:open_at, :utc_datetime)
    field(:close_at, :utc_datetime)
    field(:is_task, :boolean)
    field(:position, :integer, default: 0)

    field(:modal_image_url, :string)
    field(:description, :string)
    field(:completion_text, :string)

    has_many(:prerequisites, AchievementPrerequisite)
    has_many(:goals, AchievementGoal)

    timestamps()
  end

  @required_fields ~w(title ability is_task position inferencer_id)a
  @optional_fields ~w(background_image_url open_at close_at
    modal_image_url description completion_text)a

  def changeset(achievement, params) do
    params =
      params
      |> convert_date(:open_at)
      |> convert_date(:close_at)

    achievement
    |> cast(params, @required_fields ++ @optional_fields)
    |> validate_required(@required_fields)
  end
end
