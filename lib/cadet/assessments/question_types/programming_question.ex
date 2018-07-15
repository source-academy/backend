defmodule Cadet.Assessments.QuestionTypes.ProgrammingQuestion do
  @moduledoc """
  The ProgrammingQuestion entity represents a Programming question.
  """
  use Cadet, :model

  embedded_schema do
    field(:content, :string)
    field(:solution_template, :string)
    field(:solution_header, :string)
    field(:solution, :string)
    field(:raw_programmingquestion, :string, virtual: true)
  end

  @required_fields ~w(content solution_template solution)a
  @optional_fields ~w(solution_header raw_programmingquestion)a

  def changeset(question, params \\ %{}) do
    question
    |> cast(params, @required_fields ++ @optional_fields)
    |> validate_required(@required_fields)
  end
end
