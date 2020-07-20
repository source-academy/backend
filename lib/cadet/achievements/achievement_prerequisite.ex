defmodule Cadet.Achievements.AchievementPrerequisite do
  @moduledoc """
  The AchievementPrerequisite entity stores metadata of a prerequisite associated to a specific achievement
  """
  use Cadet, :model

  alias Cadet.Achievements.Achievement

  @primary_key false
  schema "achievement_prerequisites" do
    belongs_to(:achievement, Achievement, primary_key: true)
    belongs_to(:prerequisite, Achievement, primary_key: true)
  end

  @required_fields ~w(achievement_id prerequisite_id)a

  def changeset(prerequisite, params) do
    prerequisite
    |> cast(params, @required_fields)
    |> validate_required(@required_fields)
    |> foreign_key_constraint(:achievement_id)
    |> foreign_key_constraint(:prerequisite_id)
  end
end
