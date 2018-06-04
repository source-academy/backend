defmodule Cadet.Assessments do
  @moduledoc """
+  Assessments context contains domain logic for assessments management such as
+  missions, sidequests, paths, etc.
+  """
  import Ecto.Changeset
  import Ecto.Query
  import Cadet.ContextHelper

  alias Timex.Timezone
  alias Timex.Duration

  alias Cadet.Repo

  alias Cadet.Assessments.Mission
  alias Cadet.Assessments.Question
  alias Cadet.Assessments.Answer
  alias Cadet.Assessments.Submission
  alias Cadet.Accounts.User
  alias Cadet.Course.Group

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

  def build_question(params, type) do
    case type do
      :programming -> create_programming_question({"type" => :programming})
      :multiple_choice -> create_multiple_choice_question({"type" => :multiple_choice})
    end

    change(changeset, %{raw_library: Poison.encode!(changeset.data.library)})
  end

  def build_answer(params) do
    changeset = Answer.changeset(%Answer{}, params)
    change(changeset, %{raw_library: Poison.encode!(changeset.data.library)})
  end

  def create_mission(params) do
    changeset = build_mission(params)
    Repo.insert(changeset)
  end

  def create_submission(mission, student) do
    changeset =
      %Submission{}
      |> Submission.changeset(%{})
      |> put_assoc(:student, student)
      |> put_assoc(:mission, mission)

    Repo.insert(changeset)
  end

  def build_grading(submission, params \\ %{}) do
    submission
    |> Submission.changeset(params)
    |> cast_assoc(:answers, required: true)
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
    case question.type do
      :multiple_choice ->
        simple_update(
          Question,
          id,
          using: &MCQQuestion.changeset/2,
          params: params
        )

      :programming ->
        simple_update(
          Question,
          id,
          using: &ProgrammingQuestion.changeset/2,
          params: params
        )
    end
  end

  def publish_mission(id) do
    mission = Repo.get(Mission, id)
    changeset = change(mission, %{is_published: true})
    Repo.update(changeset)
  end

  def get_question(id, opts \\ [preload: true]) do
    Repo.get(Question, id)
  end

  def all_pending_gradings do
    Repo.all(
      from(
        s in Submission,
        where: s.status == "submitted",
        preload: [student: [:user], mission: []]
      )
    )
  end

  def submissions_of_mission(id) when is_binary(id) do
    mission = Repo.get!(Mission, id)
    submissions_of_mission(mission)
  end

  def submissions_of_mission(mission) do
    Repo.all(
      from(
        s in Submission,
        where: s.mission_id == ^mission.id,
        preload: [student: [:user]]
      )
    )
  end

  def students_not_attempted(mission) do
    Repo.all(
      from(
        s in User,
        where: s.role == "student",
        left_join: sub in Submission,
        on: sub.student_id == s.id and sub.mission_id == ^mission.id,
        where: is_nil(sub.student_id),
        select: s
      )
    )
  end

  def pending_gradings_of(staff) do
    Repo.all(
      from(
        s in Submission,
        join: dg in Group,
        on: s.student_id == dg.student_id,
        where: s.status == "submitted" and dg.staff_id == ^staff.id,
        preload: [student: [:user], mission: []]
      )
    )
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

  def create_question(params, type, mission_id) do
    mission = get_mission(mission_id)
    create_question_for_mission(params, type, mission)
  end

  def create_question_for_mission(params, type, mission) do
    Repo.transaction(fn ->
      mission = Repo.preload(mission, :questions)
      questions = mission.questions

      changeset =
        params
        |> build_question(type)
        |> put_assoc(:mission, mission)
        |> put_display_order(questions)

      case Repo.insert(changeset) do
        {:ok, question} -> question
        {:error, changeset} -> Repo.rollback(changeset)
      end
    end)
  end

  def find_submission(mission = %mission{}, student) do
    find_submission(mission.id, student)
  end

  def find_submission(mission_id, student) do
    Repo.one(
      from(
        submission in Submission,
        where: submission.mission_id == ^mission_id and submission.student_id == ^student.id
      )
    )
  end

  def attempt_mission(id, student) when is_binary(id) do
    mission = Repo.get(Mission, id)

    if mission == nil do
      {:error, :mission_not_found}
    else
      attempt_mission(mission, student)
    end
  end

  def attempt_mission(mission, student) do
    # Check for existing submission by student
    submission = find_submission(mission, student)

    if submission != nil do
      {:ok, submission}
    else
      create_submission(mission, student)
    end
  end

  def can_open?(id, user, student) do
    can_attempt?(id, user) and find_submission(id, student) != nil
  end

  def can_attempt_mission?(mission, user) do
    if user.role == :staff do
      true
    else
      mission.is_published and opened?(mission)
    end
  end

  def can_attempt?(id, user) do
    mission = get_mission(id)
    can_attempt_mission?(mission, user)
  end

  def opened?(mission) do
    timezone = Timezone.get("Asia/Singapore", Timex.now())
    date = Timezone.convert(mission.open_at, timezone)
    Timex.before?(date, Timex.now())
  end

  def prepare_workspace(id, question_order, student) when is_binary(id) do
    mission = Repo.get(Mission, id)

    if mission == nil do
      {:error, :mission_not_found}
    else
      prepare_workspace(mission, question_order, student)
    end
  end

  def prepare_workspace(mission, question_order, student) do
    # Ensure student attempted the mission
    submission = find_submission(mission, student)
    student = Repo.preload(student, :user)

    if submission == nil do
      {:error, :mission_not_attempted}
    else
      question =
        case get_mission_question(mission, question_order, true) do
          {:ok, question} -> question
          {:error, _} -> nil
        end

      previous_question =
        case get_mission_question(mission, question_order - 1) do
          {:ok, question} -> question
          {:error, _} -> nil
        end

      next_question =
        case get_mission_question(mission, question_order + 1) do
          {:ok, question} -> question
          {:error, _} -> nil
        end

      # Need to pass answer only if programming question
      extra =
        if question.type == "programming" do
          prepare_programming_question(
            question,
            submission
          )
        else
          %{type: :mcq_question}
        end

      Map.merge(extra, %{
        student: student,
        mission: mission,
        question: question,
        next_question: next_question,
        previous_question: previous_question
      })
    end
  end

  def get_submission(id) do
    Submission
    |> Repo.get(id)
    |> Repo.preload(
      mission: [],
      student: [:user],
      answers: [:question]
    )
  end

  def get_or_create_answer(question, submission) do
    answer = get_answer(question, submission)

    if answer == nil do
      {:ok, answer} = create_answer(question, submission)
      answer
    else
      answer
    end
  end

  def create_answer(question, submission) do
    %{}
    |> Answer.changeset(%{})
    |> put_assoc(:submission, submission)
    |> put_assoc(:question, question)
    |> Repo.insert()
  end

  def delete_question(id) do
    question = Repo.get(Question, id)
    Repo.delete(question)
  end

  def get_answer(question, submission) do
    Repo.one(
      from(
        answer in Answer,
        where: answer.submission_id == ^submission.id and answer.question_id == ^question.id
      )
    )
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

  def student_submissions(student) do
    Repo.all(
      from(
        s in Submission,
        where: s.student_id == ^student.id,
        join: a in Mission,
        on: a.id == s.mission_id,
        select: s,
        preload: [mission: a]
      )
    )
  end

  def submit_mission(id, student) do
    change_submission_status(id, student, :submitted)
  end

  def unsubmit_submission(id) do
    submission = Repo.get(Submission, id)
    student = Repo.get(Student, submission.student_id)
    change_submission_status(submission.mission_id, student, :attempting)
  end

  def student_submissions(student, missions) when is_list(missions) do
    student
    |> student_submissions()
    |> Enum.filter(fn s ->
      Enum.find(missions, &(&1.id == s.mission_id)) != nil
    end)
  end

  def question_name(mission, order) do
    prefix =
      case mission.category do
        :mission -> "mission"
        :sidequest -> "sidequest"
        :contest -> "contest"
        :path -> "path"
      end

    prefix <> "_" <> mission.name <> "_q" <> order
  end

  def update_grading(id, params, grader) do
    Repo.transaction(fn ->
      submission =
        id
        |> get_submission
        |> Repo.preload(:answers)

      changeset = build_grading(submission, params)

      # Get previous marks
      previous_marks =
        submission.answers
        |> Enum.map(& &1.marks)
        |> Enum.sum()

      # Update Programming Answers
      for {_, ps} <- params["answers"] do
        previous =
          Enum.find(
            submission.answers,
            &(&1.id == String.to_integer(ps["id"]))
          )

        changeset = Answer.changeset(previous, ps)
        Repo.update!(changeset)
      end

      total_marks =
        params["answers"]
        |> Enum.map(fn {_, params} -> params["marks"] end)
        |> Enum.map(fn mark ->
          {parsed, _} = Float.parse(mark)
          parsed
        end)
        |> Enum.sum()

      max_marks =
        submission.answers
        |> Enum.map(& &1.question.weight)
        |> Enum.sum()

      total_marks = Enum.min([total_marks, max_marks])
      max_xp = submission.mission.max_xp
      previous_xp = previous_marks / max_marks * max_xp
      total_xp = total_marks / max_marks * max_xp
      to_subtract = submission.override_xp || previous_xp

      to_add =
        if params["override_xp"] == "" do
          total_xp
        else
          String.to_integer(params["override_xp"])
        end

      delta_xp = round(to_add - to_subtract)
      update = if previous_marks > 0, do: " update", else: ""

      # Increase XP
      mission = submission.mission
      name = mission.name

      {:ok, xp_history} =
        Course.create_xp_history(
          %{
            "reason" => "#{name} XP#{update}. (#{total_marks}/#{max_marks})",
            "amount" => delta_xp
          },
          submission.student_id,
          grader.id
        )

      # Set submission to graded
      submission
      |> Submission.changeset(params)
      |> change(%{status: :graded})
      |> Repo.update!()

      submission
    end)
  end

  def prepare_game(student) do
    # Get all non-attempted mission
    missions =
      Repo.all(
        from(
          a in Mission,
          left_join: s in Submission,
          on: a.id == s.mission_id and s.student_id == ^student.id,
          where: is_nil(s.student_id),
          select: a
        )
      )

    # Filter those can be attempted, min by order, mission first
    missions =
      missions
      |> Enum.filter(&(&1.type != :path and can_attempt?(&1, student.user)))

    if Enum.empty?(missions) do
      nil
    else
      [hd | _] = Enum.sort_by(missions, &story_name_pair/1, &compare_story_name_pair/2)
      hd
    end
  end

  def story_name_pair(mission) do
    {mission.type, mission.name}
  end

  def compare_story_name_pair({t1, n1}, {t2, n2}) do
    cond do
      t1 == t2 -> n1 <= n2
      t1 == :mission -> true
      t1 == :sidequest and t2 == :mission -> false
      t1 == :contest and t2 == :mission -> false
      t1 == :contest and t2 == :sidequest -> false
    end
  end

  def story_name(mission) do
    type = Atom.to_string(mission.type)
    String.downcase(type) <> "-" <> mission.name
  end

  defp create_concrete_question(question, type) do
    %{}
    |> build_question(type)
    |> put_assoc(:question, question)
    |> Repo.insert()
  end

  defp prepare_programming_question(question, submission) do
    answer =
      get_or_create_answer(
        question,
        submission
      )

    %{
      type: :programming,
      answer: answer
    }
  end

  def get_student_submission(mission_id, student) do
    Repo.get_by(
      Submission,
      mission_id: mission_id,
      student_id: student.id
    )
  end

  defp change_submission_status(mission_id, student, new_status) do
    Repo.transaction(fn ->
      # 1. Get submission
      submission = get_student_submission(mission_id, student)

      # 2. Change submission status and set submitted_at timestamp if necessary
      submitted_at =
        if new_status == :submitted,
          do: Timex.now(),
          else: submission.submitted_at

      submission
      |> change(%{status: new_status, submitted_at: submitted_at})
      |> Repo.update!()
    end)
  end
end
