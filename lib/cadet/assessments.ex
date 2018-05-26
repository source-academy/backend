defmodule Cadet.Assessments do
  @moduledoc """
  Assessments context contains domain logic for assessments management such as
  missions, sidequests, paths, etc.
  """
  use Cadet, :context

  alias Cadet.Assessments.QuestionTypes.MCQQuestion
  alias Cadet.Assessments.QuestionTypes.ProgrammingQuestion

  def create_multiple_choice_question(json_attr) when is_binary(json_attr) do
    %MCQQuestion{}
    |> MCQQuestion.changeset(%{raw_mcqquestion: json_attr})
  end

  def create_multiple_choice_question(attr = %{}) do
    %MCQQuestion{}
    |> MCQQuestion.changeset(attr)
  end

  def create_programming_question(json_attr) when is_binary(json_attr) do
    %ProgrammingQuestion{}
    |> ProgrammingQuestion.changeset(%{raw_programmingquestion: json_attr})
  end

  def create_programming_question(attr = %{}) do
    %ProgrammingQuestion{}
    |> ProgrammingQuestion.changeset(attr)
  end
end
