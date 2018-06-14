defmodule Cadet.Assessments.GradingInfo do
  @moduledoc """
  The GradingInfo represents the Grading of a particular 
  ProgrammingQuestion.
  """
  use Ecto.Schema

  import Ecto.Changeset

  embedded_schema do
    field(:marks, :integer)
    field(:comment, :string)
    # TODO add once assessments is merged
    # belongs_to(:question, Assessments.Question)
  end

  # TODO add :question once assessments is merged
  @required_fields ~w(marks comment)a

  def changeset(grading_info, params \\ %{}) do
    grading_info
    |> cast(params, @required_fields)
    |> validate_required(@required_fields)
  end
end
