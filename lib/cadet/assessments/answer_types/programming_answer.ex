defmodule Cadet.Assessments.AnswerTypes.ProgrammingAnswer do
  @moduledoc """
  The ProgrammingQuestion entity represents a Programming question.
  """
  use Ecto.Schema

  import Ecto.Changeset

  embedded_schema do
    field(:code, :string)
  end

  @required_fields ~w(code)a

  def changeset(answer, params \\ %{}) do
    answer
    |> cast(params, @required_fields)
    |> validate_required(@required_fields)
  end
end
