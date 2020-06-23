defmodule Cadet.Achievements.AchievementModal do
  @moduledoc """
  The Achievement entity stores metadata of a students' assessment
  """
  use Cadet, :model
  use Arc.Ecto.Schema

  alias Cadet.Achievements.Achievement

  schema "achievements" do
    field(:modalImageUrl, :string)
    field(:description, :string)
    field(:goalText, :string)
    field(:completionText, :string)

    belongs_to(:achievement, Achievement)
    timestamps()
  end

  @required_fields ~w(title ability exp is_task prerequisiteIDs goal progress)a

  def changeset(assessment, params) do
    assessment
    |> cast(params, @required_fields)
    |> validate_required(@required_fields)
  end
end
