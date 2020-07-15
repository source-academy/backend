defmodule Cadet.Achievements.AchievementPrerequisite do
  @moduledoc """
  The AchievementPrerequisite entity stores metadata of a prerequisite associated to a specific achievement
  """
  use Cadet, :model

  alias Cadet.Achievements.Achievement

  schema "achievement_prerequisites" do
    field(:inferencer_id, :integer)
    belongs_to(:achievement, Achievement)
    timestamps()
  end

  @required_fields ~w(inferencer_id achievement_id)a

  def changeset(assessment, params) do
    assessment
    |> cast(params, @required_fields)
    |> validate_required(@required_fields)
    |> foreign_key_constraint(:achievement_id)
  end
end
