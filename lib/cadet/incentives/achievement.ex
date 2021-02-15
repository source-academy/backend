defmodule Cadet.Incentives.Achievement do
  @moduledoc """
  Represents an achievement.
  """
  use Cadet, :model

  alias Cadet.Incentives.{AchievementPrerequisite, AchievementToGoal}

  @valid_abilities ~w(Core Community Effort Exploration Flex)

  @primary_key {:uuid, :binary_id, autogenerate: false}
  schema "achievements" do
    field(:title, :string)
    field(:ability, :string)
    field(:card_tile_url, :string)

    field(:open_at, :utc_datetime)
    field(:close_at, :utc_datetime)
    field(:is_task, :boolean)
    field(:position, :integer)

    field(:canvas_url, :string)
    field(:description, :string)
    field(:completion_text, :string)

    has_many(:prerequisites, AchievementPrerequisite, on_replace: :delete)
    has_many(:goals, AchievementToGoal, on_replace: :delete)

    field(:prerequisite_uuids, {:array, :binary_id}, virtual: true)
    field(:goal_uuids, {:array, :binary_id}, virtual: true)
  end

  @required_fields ~w(uuid title ability is_task position)a
  @optional_fields ~w(card_tile_url open_at close_at canvas_url description
    completion_text prerequisite_uuids goal_uuids)a

  def changeset(achievement, params) do
    params =
      params
      |> convert_date(:open_at)
      |> convert_date(:close_at)

    achievement
    |> cast(params, @required_fields ++ @optional_fields)
    |> validate_required(@required_fields)
    |> validate_inclusion(:ability, @valid_abilities)
    |> cast_join_ids(
      :prerequisite_uuids,
      :prerequisites,
      &%{achievement_uuid: &1, prerequisite_uuid: &2},
      :uuid
    )
    |> cast_join_ids(
      :goal_uuids,
      :goals,
      &%{achievement_uuid: &1, goal_uuid: &2},
      :uuid
    )
  end

  def valid_abilities, do: @valid_abilities
end
