defmodule Cadet.Achievements.AchievementGoal do

  use Cadet, :model
  use Arc.Ecto.Schema

  alias Cadet.Achievements.Achievement
  
  schema "achievement_goals" do
    field(:goal_id, :integer)
    field(:goal_text, :string)
    field(:goal_progress, :integer)
    field(:goal_target, :integer)

    belongs_to(:achievement, Achievement)

    timestamps()
  end 

  @required_fields ~w(goal_id goal_text goal_progress goal_target achievement_id)a

  def changeset(assessment, params) do
    assessment
    |> cast(params, @required_fields)
    |> validate_required(@required_fields)
    |> foreign_key_constraint(:achievement_id)
  end
end 