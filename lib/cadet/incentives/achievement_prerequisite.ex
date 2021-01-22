defmodule Cadet.Incentives.AchievementPrerequisite do
  @moduledoc """
  Represents achievement prerequisites.
  """
  use Cadet, :model

  alias Cadet.Incentives.Achievement

  @primary_key false
  @foreign_key_type :binary_id
  schema "achievement_prerequisites" do
    belongs_to(:achievement, Achievement,
      foreign_key: :achievement_uuid,
      primary_key: true,
      references: :uuid
    )

    belongs_to(:prerequisite, Achievement,
      foreign_key: :prerequisite_uuid,
      primary_key: true,
      references: :uuid
    )
  end

  @required_fields ~w(achievement_uuid prerequisite_uuid)a

  def changeset(prerequisite, params) do
    prerequisite
    |> cast(params, @required_fields)
    |> validate_required(@required_fields)
    |> foreign_key_constraint(:achievement_uuid)
    |> foreign_key_constraint(:prerequisite_uuid)
  end
end
