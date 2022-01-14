defmodule Cadet.Incentives.Goal do
  @moduledoc """
  Represents a goal.
  """
  use Cadet, :model

  alias Cadet.Courses.Course
  alias Cadet.Incentives.{AchievementToGoal, GoalProgress}

  @type t :: %__MODULE__{}

  @primary_key {:uuid, :binary_id, autogenerate: false}
  schema "goals" do
    field(:text, :string)
    field(:target_count, :integer)

    field(:type, :string)
    field(:meta, :map)

    belongs_to(:course, Course)
    has_many(:progress, GoalProgress, foreign_key: :goal_uuid)
    has_many(:achievements, AchievementToGoal, on_replace: :delete_if_exists)
  end

  @required_fields ~w(uuid text target_count type meta course_id)a

  def changeset(goal, params) do
    goal
    |> cast(params, @required_fields)
    |> validate_required(@required_fields)
    |> foreign_key_constraint(:course_id)
  end
end
