defmodule Cadet.Assessments.Answer do
  @moduledoc false
  use Cadet, :model

  alias Cadet.Assessments.Mission

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
    |> put_json
  end

  defp put_json(changeset) do
    change = get_change(changeset, :raw_answer)
    
    if change do
      json = Poison.decode!(change)

      if json != nil do
        put_change(changeset, :json, json)
      else
        changeset
      end
    else
      changeset
    end
  end
end
