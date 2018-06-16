defmodule Cadet.Assessments.Grading do
  @moduledoc """
  The Grading represents the Grading of a Submission by a Student.
  """
  use Ecto.Schema
  alias Cadet.Assessments.GradingInfo

  import Ecto.Changeset

  schema "gradings" do
    embeds_many(:grading_infos, GradingInfo)

    timestamps()
  end

  @required_fields ~w(weight marks grading_infos)a
  @optional_fields ~w(comment)

  def changeset(answer, params \\ %{}) do
    answer
    |> cast(params, @required_fields ++ @optional_fields)
    |> cast_embed(:grading_infos, with: &GradingInfo.changeset/2, required: true)
    |> validate_required(@required_fields)
  end
end
