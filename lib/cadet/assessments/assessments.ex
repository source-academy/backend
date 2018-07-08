defmodule Cadet.Assessments do
  @moduledoc """
  Assessments context contains domain logic for assessments management such as
  missions, sidequests, paths, etc.
  """
  use Cadet, [:context, :display]

  import Ecto.Query

  alias Cadet.Assessments.Assessment
  alias Cadet.Assessments.Question

  def all_assessments(assessment_type) do
    Assessment
    |> where(type: ^assessment_type)
    |> Repo.all()
  end

  def all_open_assessments(assessment_type) do
    Assessment
    |> where(is_published: true)
    |> where(type: ^assessment_type)
    |> where([a], a.open_at <= from_now(1, "second"))
    |> Repo.all()
  end

  def assessments_due_soon() do
    Assessment
    |> where(is_published: true)
    |> where([a], a.open_at <= from_now(1, "second"))
    |> where([a], a.close_at >= from_now(1, "second"))
    |> where([a], a.close_at <= from_now(1, "week"))
    |> Repo.all()
  end

  def create_assessment(params) do
    %Assessment{}
    |> Assessment.changeset(params)
    |> Repo.insert()
  end

  def update_assessment(id, params) do
    simple_update(
      Assessment,
      id,
      using: &Assessment.changeset/2,
      params: params
    )
  end

  def update_question(id, params) do
    simple_update(
      Question,
      id,
      using: &Question.changeset/2,
      params: params
    )
  end

  def publish_assessment(id) do
    simple_update(
      Assessment,
      id,
      using: &Assessment.changeset/2,
      params: %{is_published: true}
    )
  end

  def create_question_for_assessment(params, assessment_id)
      when is_binary(assessment_id) or is_integer(assessment_id) do
    Repo.transaction(fn ->
      assessment =
        Assessment
        |> where(id: ^assessment_id)
        |> join(:left, [a], q in Question, q.assessment_id == a.id)
        |> preload([a, q], questions: q)
        |> Repo.one()

      params_with_assessment_id = Map.put_new(params, :assessment_id, assessment.id)

      changeset =
        %Question{}
        |> Question.changeset(params_with_assessment_id)
        |> put_display_order(assessment.questions)

      case Repo.insert(changeset) do
        {:ok, question} -> question
        {:error, changeset} -> Repo.rollback(changeset)
      end
    end)
  end

  def delete_question(id) do
    question = Repo.get(Question, id)
    Repo.delete(question)
  end

  # TODO: Decide what to do with these methods
  # def create_multiple_choice_question(json_attr) when is_binary(json_attr) do
  #  %MCQQuestion{}
  #  |> MCQQuestion.changeset(%{raw_mcqquestion: json_attr})
  # end

  # def create_multiple_choice_question(attr = %{}) do
  #  %MCQQuestion{}
  #  |> MCQQuestion.changeset(attr)
  # end

  # def create_programming_question(json_attr) when is_binary(json_attr) do
  #  %ProgrammingQuestion{}
  #  |> ProgrammingQuestion.changeset(%{raw_programmingquestion: json_attr})
  # end

  # def create_programming_question(attr = %{}) do
  #  %ProgrammingQuestion{}
  #  |> ProgrammingQuestion.changeset(attr)
  # end
end
