defmodule Cadet.Incentives.Goal do
  @moduledoc """
  Represents a goal.
  """
  use Cadet, :model

  alias Cadet.Incentives.GoalProgress

  @primary_key {:uuid, :binary_id, autogenerate: false}
  schema "goals" do
    field(:text, :string)
    field(:max_xp, :integer)

    field(:type, :string)
    field(:meta, :map)

    has_many(:progress, GoalProgress, foreign_key: :goal_uuid)
  end

  @required_fields ~w(uuid text max_xp type meta)a

  def changeset(goal, params) do
    goal
    |> cast(params, @required_fields)
    |> validate_required(@required_fields)
  end
end
