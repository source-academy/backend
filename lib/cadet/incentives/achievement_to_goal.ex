defmodule Cadet.Incentives.AchievementToGoal do
  @moduledoc """
  Joins achievements to goals.
  """
  use Cadet, :model

  alias Cadet.Incentives.{Achievement, Goal}

  @primary_key false
  @foreign_key_type :binary_id
  schema "achievement_to_goal" do
    belongs_to(:achievement, Achievement,
      foreign_key: :achievement_uuid,
      primary_key: true,
      references: :uuid
    )

    belongs_to(:goal, Goal, foreign_key: :goal_uuid, primary_key: true, references: :uuid)
  end

  @required_fields ~w(achievement_uuid goal_uuid)a

  def changeset(join, params) do
    join
    |> cast(params, @required_fields)
    |> validate_required(@required_fields)
    |> foreign_key_constraint(:achievement_uuid)
    |> foreign_key_constraint(:goal_uuid)
  end
end
