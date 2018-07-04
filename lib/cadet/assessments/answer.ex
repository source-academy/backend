defmodule Cadet.Assessments.Answer do
  @moduledoc """
  Answers model contains domain logic for answers management for
  programming and multiple choice questions.
  """
  use Cadet, :model

  alias Cadet.Assessments.Submission
  alias Cadet.Assessments.Question

  schema "answers" do
    field(:marks, :float, default: 0.0)
    field(:answer, :map)
    field(:raw_answer, :string, virtual: true)
    belongs_to(:submission, Submission)
    belongs_to(:question, Question)
    timestamps()
  end

  @required_fields ~w(answer submission_id question_id)a
  @optional_fields ~w(marks raw_answer)a

  def changeset(answer, params) do
    answer
    |> cast(params, @required_fields ++ @optional_fields)
    |> validate_required(@required_fields)
    |> validate_number(:marks, greater_than_or_equal_to: 0.0)
    |> foreign_key_constraint(:submission_id)
    |> foreign_key_constraint(:question_id)
    |> validate_answer_content()
    |> put_json(:answer, :raw_answer)
  end

  defp validate_answer_content(changeset) do
    case changeset.valid? do
      true ->
        IO.puts(inspect(changeset))
        changeset

      false ->
        changeset
    end
  end
end
