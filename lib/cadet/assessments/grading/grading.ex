defmodule Cadet.Assessments.Grading do
  @moduledoc """
  The Grading represents the Grading of a Submission by a Student.
  """
  use Ecto.Schema

  import Ecto.Changeset

  schema "gradings" do
    field(:weight, :integer)
    field(:marks, :integer)
    field(:comment, :string)

    timestamps()
  end

  @required_fields ~w(weight marks)a
  @optional_fields ~w(comment)

  def changeset(answer, params \\ %{}) do
    answer
    |> cast(params, @required_fields ++ @optional_fields)
    |> validate_required(@required_fields)
  end
end
