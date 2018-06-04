defmodule Cadet.Assessments.Question do
  @moduledoc """
+  Questions model contains domain logic for questions management including
   programming and multiple choice questions
+  """
  use Cadet, :model

  alias Cadet.Assessments.Mission
  alias Cadet.Assessments.ProblemType

  @default_library %{
    week: 3,
    globals: [],
    externals: [],
    files: []
  }

  schema "questions" do
    field :title, :string
    field :display_order, :integer
    field :weight, :integer
    field :question, :map
    field :type, ProblemType
    field :raw_question, :string, virtual: true
    belongs_to :mission, Mission
    timestamps()
  end

  @required_fields ~w(title weight question type library)a
  @optional_fields ~w(display_order raw_question raw_library)a

  def changeset(question, params) do
    question
    |> cast(params, @required_fields ++ @optional_fields)
    |> validate_required(@required_fields)
    |> validate_number(:weight, greater_than_or_equal_to: 0)
    |> put_json
    |> put_library
  end

  defp put_json(changeset) do
    change = get_change(changeset, :raw_question)

    if change do
      json = Poison.decode!(change)

      if json != nil do
        put_change(changeset, :question, json)
      else
        changeset
      end
    else
      changeset
    end
  end

  defp put_library(changeset) do
    change = get_change(changeset, :raw_library)

    if change do
      json = Poison.decode!(change)

      if json != nil do
        put_change(changeset, :library, json)
      else
        changeset
      end
    else
      changeset
    end
  end
end
