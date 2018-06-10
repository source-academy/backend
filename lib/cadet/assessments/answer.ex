defmodule Cadet.Assessments.Answer do
  @moduledoc false
  use Cadet, :model

  alias Cadet.Assessments.ProblemType

  schema "answers" do
    field :marks, :float, default: 0.0
    field :answer, :map
    field :type, ProblemType
    field :raw_answer, :string, virtual: true
    belongs_to :submission, Submission
    belongs_to :question, Question
    timestamps()
  end

  @required_fields ~w(answer type)a
  @optional_fields ~w(marks raw_answer)a

  def changeset(answer, params) do
    answer
    |> cast(params, @required_fields ++ @optional_fields)
    |> validate_required(@required_fields)
    |> validate_number(:marks, greater_than_or_equal_to: 0.0)
    |> put_answer
  end

  defp put_answer(changeset) do
    json = Poison.decode(get_change(changeset, :raw_answer))
    type = get_change(changeset, :type)

    case type do
      :programming ->
        put_change(changeset, :answer, ProgrammingAnswer.changeset(changeset, json))

      :multiple_choice ->
        put_change(changeset, :answer, MCQAnswer.changeset(changeset, json))
    end
  end
end
