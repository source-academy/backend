defmodule Cadet.Assessments do
  @moduledoc """
  Assessments context contains domain logic for assessments management such as
  missions, sidequests, paths, etc.
  """
  use Cadet, :context

  alias Cadet.Assessments.QuestionTypes.MCQQuestion
  alias Cadet.Assessments.QuestionTypes.ProgrammingQuestion

  import Ecto.Changeset
  import Ecto.Query
  
  alias Timex.Timezone
  alias Timex.Duration

  alias Cadet.Repo

  alias Cadet.Assessments.Assessment
  alias Cadet.Assessments.Question
  
  alias Cadet.Course
  alias Cadet.Course.Group
  alias Cadet.Accounts

  def all_assessments, do: Repo.all(Assessment)

  def all_assessments(type) do
    Repo.all(from a in Assessment, where: a.mission.category == ^type)
  end

  def all_open_assessments(type) do
    now = Timex.now()
    Repo.all(from a in Assessment, where: a.mission.category == ^type)
    |> Enum.filter(&(&1.is_published && Timex.before?(&1.mission.open_at, now)))
  end

  def assessments_due_soon() do
    now = Timex.now()
    week_after = Timex.add(now, Duration.from_weeks(1))
    all_assessments()
    |> Enum.filter(&(
      &1.is_published &&
      Timex.before?(&1.mission.open_at, now) &&
      Timex.before?(&1.mission.close_at, week_after)
    ))
  end

  def build_assessment(params) do
    changeset = %Assessment{}
    |> Assessment.changeset(params)

    #change(changeset, %{raw_library: Poison.encode!(changeset.data.library)})
  end

  def build_question(params) do
    %Question{}
    |> Question.changeset(params)
  end

  #def build_test_case(params) do
  #  %TestCase{}
  #  |> TestCase.changeset(params)
  #end

  #def build_programming_answer(params) do
  #  %ProgrammingAnswer{}
  #  |> ProgrammingAnswer.changeset(params)
  #end

  def create_assessment(params) do
    changeset = build_assessment(params)
    Repo.insert(changeset)
  end

  def change_question(question, params) do
    Question.changeset(question, params)
  end

  #def change_test_case(test_case, params) do
  #  TestCase.changeset(test_case, params)
  #end

  #def create_submission(assessment, student) do
  #  changeset = %Submission{}
  #    |> Submission.changeset(%{})
  #    |> put_assoc(:student, student)
  #    |> put_assoc(:assessment, assessment)
  #  Repo.insert(changeset)
  #end

  #def build_grading(submission, params \\ %{}) do
  #  submission
  #  |> Submission.changeset(params)
  #  |> cast_assoc(:answers, required: true)
  #end

  #def create_test_case(params, programming_question_id) do
  #  programming_question = Repo.get(ProgrammingQuestion,
  #   programming_question_id)
  #  changeset = params
  #    |> build_test_case()
  #    |> put_assoc(:programming_question, programming_question)
  #  Repo.insert(changeset)
  #end

  def change_assessment(id, params \\ :empty) do
    assessment = Repo.get(Assessment, id)
    Assessment.changeset(assessment, params)
    #|> change(%{raw_library: Poison.encode!(assessment.library)})
  end

  def update_assessment(id, params) do
    simple_update(Assessment, id,
      using: &Assessment.changeset/2,
      params: params)
  end

  def update_question(id, params) do
    simple_update(Question, id,
      using: &Question.changeset/2,
      params: params)
  end

  def publish_assessment(id) do
    assessment = Repo.get(Assessment, id)
    changeset = change(assessment, %{is_published: true})
    Repo.update(changeset)
  end

  def get_question(id, opts \\ [preload: true]) do
    Repo.get(Question, id)
  end

  #def update_test_case(id, params) do
  #  test_case = Repo.get(TestCase, id)
  #  changeset = TestCase.changeset(test_case, params)
  #  Repo.update(changeset)
  #end

  #def delete_test_case(id) do
  #  test_case = Repo.get(TestCase, id)
  #  Repo.delete(test_case)
  #end

  def all_pending_gradings do
    Repo.all(
      from s in Submission,
      where: s.status == "submitted",
      preload: [:student, :assessment]
    )
  end

  def submissions_of_assessment(id) when is_binary(id) do
    assessment = Repo.get!(Assessment, id)
    submissions_of_assessment(assessment)
  end

  def submissions_of_assessment(assessment) do
    Repo.all(
      from s in Submission,
      where: s.assessment_id == ^assessment.id,
      preload: [:student]
    )
  end

  def students_not_attempted(assessment) do
    Repo.all(
      from s in Student,
      left_join: sub in Submission, on: (
        sub.student_id == s.id
        and sub.assessment_id == ^assessment.id
      ),
      where: is_nil(sub.student_id) and not s.is_phantom,
      select: s,
      preload: [:student]
    )
  end

  def pending_gradings_of(staff) do
    Repo.all(
      from s in Submission,
      where: s.status == "submitted" and s.grader_id == ^staff.id,
      preload: [:student, :assessment]
    )
  end

  def get_assessment_and_questions(id) do
    Repo.one(
      from a in Assessment,
      where: (a.id == ^id),
      left_join: m in Mission, on: m.assessment_id == ^id,
      left_join: q in Question, on: q.mission_id == m.id,
      preload: [:question]
    )
  end

  def get_assessment(id) do
    Repo.get(Assessment, id)
  end

  def create_question(params, type, mission_id)
    when is_binary(mission_id) do
    mission = Repo.get(Assessment, mission_id)
    create_question(params, type, mission)
  end

  def create_question(params, type, mission) do
    Repo.transaction fn ->
      mission = Repo.preload(mission, :questions)
      questions = mission.questions
      changeset = params
        |> build_question()
        |> put_assoc(:mission, mission)
        |> put_display_order(questions)
      case Repo.insert(changeset) do
        {:ok, question} -> create_concrete_question(question, type)
        {:error, changeset} -> Repo.rollback(changeset)
      end
    end
  end

  def find_submission(%Assessment{} = assessment, student) do
    find_submission(assessment.id, student)
  end

  def find_submission(assessment_id, student) do
    Repo.one(
      from submission in Submission,
      where: (
        submission.assessment_id == ^assessment_id
        and submission.student_id == ^student.id
      )
    )
  end

  def attempt_assessment(id, student) when is_binary(id) do
    assessment = Repo.get(Assessment, id)

    if assessment == nil do
      {:error, :assessment_not_found}
    else
      attempt_assessment(assessment, student)
    end
  end

  def attempt_assessment(assessment, student) do
    # Check for existing submission by student
    submission = find_submission(assessment, student)

    if submission != nil do
      {:ok, submission}
    else
      create_submission(assessment, student)
    end
  end

  def can_open?(id, user, student) do
    can_attempt?(id, user) && find_submission(id, student) != nil
  end

  def can_attempt?(%Assessment{} = assessment, user) do
    if Accounts.staff?(user) do
      true
    else
      assessment.is_published && opened?(assessment)
    end
  end

  def can_attempt?(id, user) do
    assessment = Repo.get(Assessment, id)
    can_attempt?(assessment, user)
  end

  def opened?(assessment) do
    timezone = Timezone.get("Asia/Singapore", Timex.now)
    date = Timezone.convert(assessment.mission.open_at, timezone)
    Timex.before?(date, Timex.now())
  end

  def get_submission(id) do
    Repo.get(Submission, id)
    |> Repo.preload([:assessment, :student, :answers]
      ])
  end

  def get_or_create_programming_answer(question, submission) do
    answer = get_programming_answer(question, submission)

    if answer == nil do
      student = Course.get_student(submission.student_id)
      owner = Accounts.get_user(student.user_id)
      # Create code
      {:ok, code} = Workspace.create_code(%{
        title: "solution",
        content: question.solution_template
      }, owner)
      {:ok, answer} = create_programming_answer(
        question,
        submission,
        code
      )
      answer
    else
      answer
    end
  end

  def create_programming_answer(question, submission, code) do
    %ProgrammingAnswer{}
    |> ProgrammingAnswer.changeset(%{})
    |> put_assoc(:submission, submission)
    |> put_assoc(:question, question)
    |> put_assoc(:code, code)
    |> Repo.insert
  end

  def delete_question(id) do
    question = Repo.get(Question, id)
    Repo.delete(question)
  end

  def get_answer(question, submission) do
    Repo.one(
      from answer in Answer,
      where: answer.submission_id == ^submission.id
        and answer.question_id == ^question.id
    )
  end

  def get_assessment_question(assessment, order, preload \\ false) do
    question = Repo.get_by(Question,
      assessment_id: assessment.id,
      display_order: order)
    if question == nil do
      {:error, :question_not_found}
    else
      {:ok, question}
    end
  end

  def student_submissions(student) do
    Repo.all(
      from s in Submission,
      where: s.student_id == ^student.id,
      join: a in Assessment, on: a.id == s.assessment_id,
      select: s,
      preload: [assessment: a]
    )
  end

  def submit_assessment(id, student) do
    change_submission_status(id, student, :submitted)
  end

  def unsubmit_submission(id) do
    submission = Repo.get(Submission, id)
    student = Repo.get(Student, submission.student_id)
    change_submission_status(submission.assessment_id, student, :attempting)
  end

  def student_submissions(student, assessments) when is_list(assessments) do
    student
    |> student_submissions()
    |> Enum.filter(fn s ->
         Enum.find(assessments, &(&1.id == s.assessment_id)) != nil
    end)
  end

  def question_name(assessment, order) do
    prefix = case assessment.mission.category do
      :mission -> "mission"
      :sidequest -> "sidequest"
      :contest -> "contest"
      :path -> "path"
    end
    prefix <> "_" <> assessment.name <> "_q" <> order
  end

  def update_grading(id, params, grader) do
    Repo.transaction fn ->
      submission = get_submission(id)
        |> Repo.preload(:answers)
      changeset = build_grading(submission, params)

      # Get previous marks
      previous_marks = submission.answers
        |> Enum.map(&(&1.marks))
        |> Enum.sum

      # Update Programming Answers
      for {_, ps} <- params["answers"] do
        previous = Enum.find(
          submission.answers,
          &(&1.id == String.to_integer(ps["id"]))
        )
        changeset = Answer.changeset(previous, ps)
        Repo.update!(changeset)
      end

      total_marks = params["answers"]
        |> Enum.map(fn {_, params} -> params["marks"] end)
        |> Enum.map(fn mark ->
          {parsed, _} = Float.parse(mark)
          parsed
        end)
        |> Enum.sum
      max_marks = submission.answers
        |> Enum.map(&(&1.question.weight))
        |> Enum.sum
      total_marks = Enum.min([total_marks, max_marks])
      max_xp = submission.assessment.max_xp
      previous_xp = (previous_marks / max_marks) * max_xp
      total_xp = (total_marks / max_marks) * max_xp
      to_subtract = submission.override_xp || previous_xp
      to_add = if params["override_xp"] == "" do
        total_xp
      else
        String.to_integer(params["override_xp"])
      end
      delta_xp = round(to_add - to_subtract)
      update = if previous_marks > 0, do: " update", else: ""

      # Increase XP
      assessment = submission.assessment
      name = display_assessment_name(assessment)
      {:ok, xp_history} = Course.create_xp_history(%{
        "reason" => "#{name} XP#{update}. (#{total_marks}/#{max_marks})",
        "amount" => delta_xp
      }, submission.student_id, grader.id)

      # Set submission to graded
      submission
      |> Submission.changeset(params)
      |> change(%{status: :graded})
      |> Repo.update!

      submission
    end
  end

  def prepare_game(student) do
    # Get all non-attempted assessment
    assessments = Repo.all(
      from a in Assessment,
        left_join: s in Submission,
          on: a.id == s.assessment_id and s.student_id == ^student.id,
        where: is_nil(s.student_id),
        select: a
    )
    # Filter those can be attempted, min by order, mission first
    assessments =
      assessments
      |> Enum.filter(&(&1.mission.category != :path && can_attempt?(&1, student.user)))
    if Enum.empty?(assessments) do
      nil
    else
      [hd | _ ] = Enum.sort_by(assessments,
        &story_name_pair/1,
        &compare_story_name_pair/2)
      hd
    end
  end

  def story_name_pair(assessment) do
    {assessment.mission.category, assessment.name}
  end

  def compare_story_name_pair({t1, n1}, {t2, n2}) do
    cond do
      t1 == t2 -> n1 <= n2
      t1 == :mission -> true
      t1 == :sidequest && t2 == :mission -> false
      t1 == :contest && t2 == :mission -> false
      t1 == :contest && t2 == :sidequest -> false
      true -> false
    end
  end

  def story_name(assessment) do
    type = Atom.to_string(assessment.mission.category)
    String.downcase(type) <> "-" <> assessment.name
  end

  defp prepare_programming_question(programming_question, submission) do
    answer = get_or_create_programming_answer(
      programming_question,
      submission
    )
    answer = Repo.preload(answer, :code)
    comments = Workspace.comments_of(answer.code)
    %{
      type: :programming_question,
      answer: answer,
      comments: comments
    }
  end

  def get_student_submission(assessment_id, student) do
    Repo.get_by(Submission,
      assessment_id: assessment_id,
      student_id: student.id)
  end

  defp change_submission_status(assessment_id, student, new_status) do
    Repo.transaction fn ->
      # 1. Get submission
      submission = get_student_submission(assessment_id, student)

      # 2. Change submission status and set submitted_at timestamp if necessary
      submitted_at = if new_status == :submitted, do: Timex.now,
        else: submission.submitted_at

      submission
      |> change(%{ status: new_status, submitted_at: submitted_at })
      |> Repo.update!
    end

  end
  
  # To be uncommented when assessments context is merged
  # def create_multiple_choice_question(json_attr) when is_binary(json_attr) do
  #   %MCQQuestion{}
  #   |> MCQQuestion.changeset(%{raw_mcqquestion: json_attr})
  # end

  # def create_multiple_choice_question(attr = %{}) do
  #   %MCQQuestion{}
  #   |> MCQQuestion.changeset(attr)
  # end

  # def create_programming_question(json_attr) when is_binary(json_attr) do
  #   %ProgrammingQuestion{}
  #   |> ProgrammingQuestion.changeset(%{raw_programmingquestion: json_attr})
  # end

  # def create_programming_question(attr = %{}) do
  #   %ProgrammingQuestion{}
  #   |> ProgrammingQuestion.changeset(attr)
  # end
end
