defmodule Cadet.Efficiency.Runtimes do
  @moduledoc """
  The Course entity stores the configuration of a particular course.
  """
  use Cadet, :model

  schema "runtimes" do
    field(:assessment_id, :integer)
    field(:question_id, :integer)
    field(:user_id, :integer)
    field(:counter, :integer)
  end

  @required_fields ~w(assessment_id question_id user_id counter)a

  def changeset(efficiency, params) do
    efficiency
    |> cast(params, @required_fields)
    |> validate_required(@required_fields)
  end
end
