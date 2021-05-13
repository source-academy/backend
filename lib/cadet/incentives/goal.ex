defmodule Cadet.Incentives.Goal do
  @moduledoc """
  Represents a goal.
  """
  use Cadet, :model

  alias Cadet.Incentives.{AchievementToGoal, GoalProgress}

  @primary_key {:uuid, :binary_id, autogenerate: false}
  schema "goals" do
    field(:text, :string)
    field(:target_count, :integer)

    field(:type, :string)
    field(:meta, :map)

    has_many(:progress, GoalProgress, foreign_key: :goal_uuid)
    has_many(:achievements, AchievementToGoal, on_replace: :delete_if_exists)
  end

  @required_fields ~w(uuid text target_count type meta)a

  def changeset(goal, params) do
    goal
    |> cast(params, @required_fields)
    |> validate_required(@required_fields)
  end
end
