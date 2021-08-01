defmodule Cadet.Incentives.GoalProgress do
  @moduledoc """
  Represents goal progress per user.
  """
  use Cadet, :model

  alias Cadet.Incentives.Goal
  alias Cadet.Accounts.CourseRegistration

  @primary_key false
  schema "goal_progress" do
    field(:count, :integer)
    field(:completed, :boolean)

    belongs_to(:course_reg, CourseRegistration, primary_key: true)

    belongs_to(:goal, Goal,
      primary_key: true,
      foreign_key: :goal_uuid,
      type: :binary_id,
      references: :uuid
    )

    timestamps()
  end

  @required_fields ~w(count completed course_reg_id goal_uuid)a

  def changeset(progress, params) do
    progress
    |> cast(params, @required_fields)
    |> validate_required(@required_fields)
    |> foreign_key_constraint(:course_reg_id)
    |> foreign_key_constraint(:goal_uuid)
  end
end
