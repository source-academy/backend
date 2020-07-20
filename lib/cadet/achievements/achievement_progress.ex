defmodule Cadet.Achievements.AchievementProgress do
  @moduledoc """
  Stores user achievement progress per goal.
  """
  use Cadet, :model

  alias Cadet.Achievements.AchievementGoal
  alias Cadet.Accounts.User

  schema "achievement_progress" do
    field(:progress, :integer)

    belongs_to(:user, User)
    belongs_to(:goal, AchievementGoal)

    timestamps()
  end

  @required_fields ~w(progress user_id goal_id)a

  def changeset(progress, params) do
    progress
    |> cast(params, @required_fields)
    |> validate_required(@required_fields)
    |> foreign_key_constraint(:user_id)
    |> foreign_key_constraint(:goal_id)
  end
end
