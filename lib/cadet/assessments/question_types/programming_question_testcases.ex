defmodule Cadet.Assessments.QuestionTypes.Testcase do
  @moduledoc """
  The Assessments.QuestionTypes.Testcase entity represents a public/opaque/secret testcase.
  """
  use Cadet, :model

  @primary_key false
  embedded_schema do
    field(:program, :string)
    field(:answer, :string)
    field(:score, :integer)
  end

  @required_fields ~w(program answer score)a

  def changeset(question, params \\ %{}) do
    question
    |> cast(params, @required_fields)
    |> validate_required(@required_fields)
    |> validate_number(:score, greater_than_or_equal_to: 0)
  end
end
