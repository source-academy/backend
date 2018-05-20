defmodule Cadet.Assessments.Question do
  @moduledoc false
  use Cadet, :model

  alias Cadet.Assessments.Mission

  schema "questions" do
    field :title, :string
    field :display_order, :integer
    field :weight, :integer
    field :question_json, :map
    field :type, ProblemType
    field :raw_json, :string, virtual: true
    belongs_to :mission, Mission
    timestamps()
  end

  @required_fields ~w(title weight question_json type)a
  @optional_fields ~w(display_order raw_json)a

  def changeset(question, params) do
    question
    |> cast(params, @required_fields ++ @optional_fields)
    |> validate_required(@required_fields)
    |> validate_number(:weight, greater_than_or_equal_to: 0)
    |> put_json
  end

  defp put_json(changeset) do
    change = get_change(changeset, :raw_json)
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
