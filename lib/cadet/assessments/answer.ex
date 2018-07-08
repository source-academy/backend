defmodule Cadet.Assessments.Answer do
  @moduledoc """
  Answers model contains domain logic for answers management for
  programming and multiple choice questions.
  """
  use Cadet, :model

  alias Cadet.Assessments.ProblemType
  alias Cadet.Assessments.Submission
  alias Cadet.Assessments.Question
  alias Cadet.Assessments.AnswerTypes.ProgrammingAnswer
  alias Cadet.Assessments.AnswerTypes.MCQAnswer

  schema "answers" do
    field(:xp, :integer, default: 0)
    field(:answer, :map)
    field(:type, ProblemType, virtual: true)
    field(:raw_answer, :string, virtual: true)
    belongs_to(:submission, Submission)
    belongs_to(:question, Question)
    timestamps()
  end

  @required_fields ~w(answer submission_id question_id type)a
  @optional_fields ~w(xp)a

  def changeset(answer, params) do
    answer
    |> cast(params, @required_fields ++ @optional_fields)
    |> add_belongs_to_id_from_model(:submission, params)
    |> add_belongs_to_id_from_model(:question, params)
    |> add_question_type_from_model(params)
    |> validate_required(@required_fields)
    |> validate_number(:xp, greater_than_or_equal_to: 0.0)
    |> foreign_key_constraint(:submission_id)
    |> foreign_key_constraint(:question_id)
    |> validate_answer_content()
  end

  defp add_question_type_from_model(changeset, params) do
    question = Map.get(params, :question)

    if is_nil(get_change(changeset, :type)) and not is_nil(question) do
      change(changeset, %{type: question.type})
    else
      changeset
    end
  end

  defp validate_answer_content(changeset) do
    if changeset.valid? do
      question_type = get_change(changeset, :type)
      answer = get_change(changeset, :answer)

      answer_content_changeset =
        case question_type do
          :programming ->
            ProgrammingAnswer.changeset(%ProgrammingAnswer{}, answer)

          :multiple_choice ->
            MCQAnswer.changeset(%MCQAnswer{}, answer)
        end

      answer_content_changeset
      |> Map.get(:valid?)
      |> case do
        true ->
          changeset

        false ->
          add_error(changeset, :answer, "invalid answer type provided for question")
      end
    else
      changeset
    end
  end
end
