defmodule Cadet.Achievements.Achievement do
  @moduledoc """
  The Achievement entity stores metadata of a students' assessment
  """
  use Cadet, :model
  use Arc.Ecto.Schema

  alias Cadet.Achievements.AchievementAbility

  schema "achievements" do
    field(:inferencer_id, :integer)
    field(:title, :string, default: 'New Achievement')
    field(:ability, AchievementAbility, default: :academic)
    field(:icon, :string, default: nil)
    field(:exp, :integer, default: 0)
    field(:open_at, :utc_datetime_usec, default: DateTime.utc_now)
    field(:close_at, :utc_datetime_usec, default: DateTime.utc_now)
    field(:is_task, :boolean, default: false)
    field(:prerequisite_ids, {:array, :integer})
    field(:goal, :integer, default: 0)
    field(:progress, :integer, default: 0)

    field(:modal_image_url, :string)
    field(:description, :string)
    field(:goal_text, :string)
    field(:completion_text, :string)

    timestamps()
  end

  @required_fields ~w(title ability exp is_task goal progress)a
  @optional_fields ~w(icon open_at close_at prerequisite_ids
    modal_image_url description goal_text completion_text)a

  def changeset(assessment, params) do
    params =
      params
      |> convert_date(:open_at)
      |> convert_date(:close_at)

    assessment
    |> cast_attachments(params, @optional_file_fields)
    |> cast(params, @required_fields ++ @optional_fields)
    |> validate_required(@required_fields)
    |> validate_open_close_date
  end

  defp validate_open_close_date(changeset) do
    validate_change(changeset, :open_at, fn :open_at, open_at ->
      if Timex.before?(open_at, get_field(changeset, :close_at)) do
        []
      else
        [open_at: "Open date must be before close date"]
      end
    end)
  end
end
