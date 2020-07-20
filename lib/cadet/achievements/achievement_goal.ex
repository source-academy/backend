defmodule Cadet.Achievements.AchievementGoal do
  @moduledoc """
  Stores achievement goals.
  """
  use Cadet, :model

  alias Cadet.Achievements.{Achievement, AchievementProgress}

  schema "achievement_goals" do
    field(:order, :integer)
    field(:text, :string)
    field(:target, :integer)

    belongs_to(:achievement, Achievement)

    has_many(:progress, AchievementProgress, foreign_key: :goal_id)
  end

  @required_fields ~w(text target order achievement_id)a

  def changeset(goal, params) do
    goal
    |> cast(params, @required_fields)
    |> validate_required(@required_fields)
    |> foreign_key_constraint(:achievement_id)
  end
end
