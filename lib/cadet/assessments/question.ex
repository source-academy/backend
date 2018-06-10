defmodule Cadet.Assessments.Question do
  @moduledoc """
  Questions model contains domain logic for questions management 
  including programming and multiple choice questions.
  """
  use Cadet, :model

  alias Cadet.Assessments.Mission
  alias Cadet.Assessments.ProblemType
  alias Cadet.Assessments.QuestionTypes

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
    |> put_question
  end

  defp put_question(changeset) do
    json = Poison.decode(get_change(changeset, :raw_question))
    type = get_change(changeset, :type)
    case type do
      :programming -> put_change(changeset, :question, &ProgrammingQuestion.changeset(changeset, json))
      :multiple_choice -> put_change(changeset, :question, &MCQQuestion.changeset(changeset, json))
>>>>>>> Changes according to question types
    end
  end
end
