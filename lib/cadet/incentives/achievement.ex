defmodule Cadet.Incentives.Achievement do
  @moduledoc """
  Represents an achievement.
  """
  use Cadet, :model

  alias Cadet.Courses.Course
  alias Cadet.Incentives.{AchievementPrerequisite, AchievementToGoal}

  @type t :: %__MODULE__{}

  @primary_key {:uuid, :binary_id, autogenerate: false}
  schema "achievements" do
    field(:title, :string)
    field(:card_tile_url, :string)
    field(:xp, :integer)
    field(:is_variable_xp, :boolean)

    field(:open_at, :utc_datetime)
    field(:close_at, :utc_datetime)
    field(:is_task, :boolean)
    field(:position, :integer)

    field(:canvas_url, :string)
    field(:description, :string)
    field(:completion_text, :string)

    belongs_to(:course, Course)
    has_many(:prerequisites, AchievementPrerequisite, on_replace: :delete)
    has_many(:goals, AchievementToGoal, on_replace: :delete_if_exists)

    field(:prerequisite_uuids, {:array, :binary_id}, virtual: true)
    field(:goal_uuids, {:array, :binary_id}, virtual: true)
  end

  @required_fields ~w(uuid title is_task position xp is_variable_xp course_id)a
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
    |> foreign_key_constraint(:course_id)
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
end
