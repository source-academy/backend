defmodule Cadet.Assessments.Question do
  @moduledoc false
  use Cadet, :model

  alias Cadet.Assessments.Mission

  schema "assessment_questions" do
    field :title, :string
    field :display_order, :integer
    field :weight, :integer
    field :question_json, :map
    belongs_to :mission, Mission
    timestamps()
  end

  @required_fields ~w(title weight question_json)a
  @optional_fields ~w(display_order)a

  def changeset(question, params) do
    question
    |> cast(params, @required_fields ++ @optional_fields)
    |> validate_required(@required_fields)
    |> validate_number(:weight, greater_than_or_equal_to: 0)
    |> validate_json(:question_json)
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
