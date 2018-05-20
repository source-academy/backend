defmodule Cadet.Assessments.Answer do
  @moduledoc false
  use Cadet, :model

  alias Cadet.Assessments.Mission

  schema "answers" do
    field :marks, :float, default: 0.0
    field :answer_json, :map
    belongs_to :submission, Submission
    belongs_to :question, Question
    timestamps()
  end

  @required_fields ~w(answer_json)a
  @optional_fields ~w(marks)a

  def changeset(answer, params) do
    answer
    |> cast(params, @required_fields ++ @optional_fields)
    |> validate_required(@required_fields)
    |> validate_number(:marks, greater_than_or_equal_to: 0.0)
    |> validate_json(:answer_json)
  end

  def validate_json(changeset, json_field) do
    validate_change(changeset, json_field, fn _, json ->
      case Map.has_key?(json, :type) do
        true -> []
        false -> [{json_field, "Invalid Question"}]
      end
    end)
  end

end
