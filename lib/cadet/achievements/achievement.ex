defmodule Cadet.Achievements.Achievement do
  @moduledoc """
  Stores achievements.
  """
  use Cadet, :model

  alias Cadet.Achievements.{AchievementGoal, AchievementPrerequisite}

  @valid_abilities ~w(Core Community Effort Exploration Flex)

  @primary_key {:id, :id, autogenerate: false}
  schema "achievements" do
    field(:title, :string)
    field(:ability, :string)
    field(:card_tile_url, :string)

    field(:open_at, :utc_datetime)
    field(:close_at, :utc_datetime)
    field(:is_task, :boolean)
    field(:position, :integer, default: 0)

    field(:canvas_url, :string)
    field(:description, :string)
    field(:completion_text, :string)

    has_many(:prerequisites, AchievementPrerequisite, on_replace: :delete)
    has_many(:goals, AchievementGoal)

    timestamps()
  end

  @required_fields ~w(id title ability is_task position)a
  @optional_fields ~w(card_tile_url open_at close_at canvas_url description completion_text)a

  def changeset(achievement, params) do
    params =
      params
      |> convert_date(:open_at)
      |> convert_date(:close_at)

    achievement
    |> cast(params, @required_fields ++ @optional_fields)
    |> validate_required(@required_fields)
    |> validate_inclusion(:ability, @valid_abilities)
    |> cast_assoc(:prerequisites)
    |> cast_assoc(:goals)
  end

  def valid_abilities, do: @valid_abilities
end
