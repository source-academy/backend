defmodule Cadet.Assessments do
  @moduledoc """
  Assessments context contains domain logic for assessments management such as
  missions, sidequests, paths, etc.
  """

  import Ecto.Changeset
  import Ecto.Query
  import Cadet.ContextHelper
  
  use Cadet, :context
  
  alias Timex.Timezone
  alias Timex.Duration

  alias Cadet.Repo

  alias Cadet.Assessments.Mission
  alias Cadet.Assessments.Question
  alias Cadet.Assessments.Answer
  alias Cadet.Assessments.Submission
  alias Cadet.Accounts.User
  alias Cadet.Course.Group
  alias Cadet.Assessments.QuestionTypes.MCQQuestion
  alias Cadet.Assessments.QuestionTypes.ProgrammingQuestion

  def all_missions, do: Repo.all(Mission)

  def all_missions(category) do
    Repo.all(from(a in Mission, where: a.category == ^category))
  end

  def all_open_missions(category) do
    now = Timex.now()

    mission_with_category = Repo.all(from(a in Mission, where: a.category == ^category))
    Enum.filter(mission_with_category, &(&1.is_published and Timex.before?(&1.open_at, now)))
  end

  def missions_due_soon() do
    now = Timex.now()
    week_after = Timex.add(now, Duration.from_weeks(1))

    all_missions()
    |> Enum.filter(
      &(&1.is_published and Timex.before?(&1.open_at, now) and
          Timex.before?(&1.close_at, week_after))
    )
  end

  def build_mission(params) do
    Mission.changeset(%Mission{}, params)
  end

  def build_question(params) do
    Question.changeset(%Question{}, params)
  end

  def create_mission(params) do
    changeset = build_mission(params)
    Repo.insert(changeset)
  end

  def update_mission(id, params) do
    simple_update(
      Mission,
      id,
      using: &Mission.changeset/2,
      params: params
    )
  end

  def update_question(id, params) do
    question = get_question(id)
    simple_update(
      Question,
      id,
      using: &Question.changeset/2,
      params: params
    )
  end

  def publish_mission(id) do
    mission = get_mission(id) 
    changeset = change(mission, %{is_published: true})
    Repo.update(changeset)
  end

  def get_question(id, opts \\ [preload: true]) do
    Repo.get(Question, id)
  end

  def get_mission_and_questions(id) do
    Repo.one(
      from(
        a in Mission,
        where: a.id == ^id,
        left_join: q in Question,
        on: q.mission_id == ^id,
        preload: [:question]
      )
    )
  end

  def get_mission(id) do
    Repo.get(Mission, id)
  end

  def create_question(params, mission_id) do
    mission = get_mission(mission_id)
    create_question_for_mission(params, mission)
  end

  def create_question_for_mission(params, mission) do
    Repo.transaction(fn ->
      mission = Repo.preload(mission, :questions)
      questions = mission.questions

      changeset =
        params
        |> build_question
        |> put_assoc(:mission, mission)
        |> put_display_order(questions)

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

  def get_mission_question(mission, order, preload \\ false) do
    question =
      Repo.get_by(
        Question,
        mission_id: mission.id,
        display_order: order
      )

    if question == nil do
      {:error, :question_not_found}
    else
      {:ok, question}
    end
  end

  #def create_multiple_choice_question(json_attr) when is_binary(json_attr) do
  #  %MCQQuestion{}
  #  |> MCQQuestion.changeset(%{raw_mcqquestion: json_attr})
  #end

  #def create_multiple_choice_question(attr = %{}) do
  #  %MCQQuestion{}
  #  |> MCQQuestion.changeset(attr)
  #end

  #def create_programming_question(json_attr) when is_binary(json_attr) do
  #  %ProgrammingQuestion{}
  #  |> ProgrammingQuestion.changeset(%{raw_programmingquestion: json_attr})
  #end

  #def create_programming_question(attr = %{}) do
  #  %ProgrammingQuestion{}
  #  |> ProgrammingQuestion.changeset(attr)
  #end

end
