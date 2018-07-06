defmodule Cadet.Assessments.Answer do
  @moduledoc """
  Answers model contains domain logic for answers management for
  programming and multiple choice questions.
  """
  use Cadet, :model

  alias Cadet.Assessments.ProblemType
  alias Cadet.Assessments.Submission
  alias Cadet.Assessments.Question

  schema "answers" do
    field(:xp, :integer, default: 0)
    field(:answer, :map)
    field(:raw_answer, :string, virtual: true)
    belongs_to(:submission, Submission)
    belongs_to(:question, Question)
    timestamps()
  end

  @required_fields ~w(answer)a
  @optional_fields ~w(xp raw_answer)a

  def changeset(answer, params) do
    answer
    |> cast(params, @required_fields ++ @optional_fields)
    |> validate_required(@required_fields)
    |> validate_number(:xp, greater_than_or_equal_to: 0.0)
    |> put_json(:answer, :raw_answer)
  end
end
