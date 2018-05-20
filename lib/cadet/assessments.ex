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
      Timex.before?(&1.open_at, now) &&
      Timex.before?(&1.close_at, week_after)
    ))
  end

  def build_assessment(params) do
    changeset = %Assessment{}
    |> Assessment.changeset(params)

    change(changeset, %{raw_library: Poison.encode!(changeset.data.library)})
  end

  def build_question(params) do
    %Question{}
    |> Question.changeset(params)
  end

  def build_programming_question(params) do
    %ProgrammingQuestion{}
    |> ProgrammingQuestion.changeset(params)
  end

  def build_test_case(params) do
    %TestCase{}
    |> TestCase.changeset(params)
  end

  def build_mcq_question(params) do
    %MCQQuestion{}
    |> MCQQuestion.changeset(params)
  end

  def build_mcq_choice(params) do
    %MCQChoice{}
    |> MCQChoice.changeset(params)
  end

  def build_programming_answer(params) do
    %ProgrammingAnswer{}
    |> ProgrammingAnswer.changeset(params)
  end

  def create_assessment(params) do
    changeset = build_assessment(params)
    Repo.insert(changeset)
  end

  def change_question(question, params) do
    Question.changeset(question, params)
  end

  def change_programming_question(programming_question, params) do
    ProgrammingQuestion.changeset(programming_question, params)
  end

  def change_test_case(test_case, params) do
    TestCase.changeset(test_case, params)
  end

  def change_mcq_question(mcq_question, params) do
    MCQQuestion.changeset(mcq_question, params)
  end

  def change_mcq_choice(mcq_choice, params) do
    MCQChoice.changeset(mcq_choice, params)
  end

  def create_submission(assessment, student) do
    changeset = %Submission{}
      |> Submission.changeset(%{})
      |> put_assoc(:student, student)
      |> put_assoc(:assessment, assessment)
    Repo.insert(changeset)
  end

  def build_grading(submission, params \\ %{}) do
    submission
    |> Submission.changeset(params)
    |> cast_assoc(:programming_answers, required: true)
  end

  def create_test_case(params, programming_question_id) do
    programming_question = Repo.get(ProgrammingQuestion,
      programming_question_id)
    changeset = params
      |> build_test_case()
      |> put_assoc(:programming_question, programming_question)
    Repo.insert(changeset)
  end

  def change_assessment(id, params \\ :empty) do
    assessment = Repo.get(Assessment, id)
    Assessment.changeset(assessment, params)
    |> change(%{raw_library: Poison.encode!(assessment.library)})
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

  def update_programming_question(id, params) do
    simple_update(ProgrammingQuestion, id,
      using: &ProgrammingQuestion.changeset/2,
      params: params)
  end

  def publish_assessment(id) do
    assessment = Repo.get(Assessment, id)
    changeset = change(assessment, %{is_published: true})
    Repo.update(changeset)
  end

  def get_question(id, opts \\ [preload: true]) do
    question = Repo.get(Question, id)
    if opts[:preload] do
      Repo.preload(question, [
        programming_question: [:test_cases],
        mcq_question: [:choices]
      ])
    else
      question
    end
  end

  def update_test_case(id, params) do
    test_case = Repo.get(TestCase, id)
    changeset = TestCase.changeset(test_case, params)
    Repo.update(changeset)
  end

  def delete_test_case(id) do
    test_case = Repo.get(TestCase, id)
    Repo.delete(test_case)
  end

  def update_mcq_choice(id, params) do
    simple_update(MCQChoice, id,
      using: &MCQChoice.changeset/2,
      params: params)
  end

  def update_mcq_question(id, params) do
    simple_update(MCQQuestion, id,
      using: &MCQQuestion.changeset/2,
      params: params)
  end

  def create_mcq_choice(params, mcq_question_id) do
    mcq_question = Repo.get(MCQQuestion, mcq_question_id)
    if mcq_question != nil do
      changeset = params
        |> build_mcq_choice()
        |> put_assoc(:mcq_question, mcq_question)
      Repo.insert(changeset)
    else
      {:error, :mcq_question_not_found}
    end
  end

  def all_pending_gradings do
    Repo.all(
      from s in Submission,
      where: s.status == "submitted",
      preload: [student: [:user], assessment: []]
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
      preload: [student: [:user]]
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
      preload: [:user]
    )
  end

  def pending_gradings_of(staff) do
    Repo.all(
      from s in Submission,
      join: dg in DiscussionGroup, on: s.student_id == dg.student_id,
      where: s.status == "submitted" and dg.staff_id == ^staff.id,
      preload: [student: [:user], assessment: []]
    )
  end

  def get_assessment_and_questions(id) do
    Repo.one(
      from a in Assessment,
      where: (a.id == ^id),
      left_join: q in Question, on: q.assessment_id == ^id,
      left_join: pq in ProgrammingQuestion, on: pq.question_id == q.id,
      left_join: mq in MCQQuestion, on: mq.question_id == q.id,
      preload: [
        questions: {
          q,
          programming_question: pq,
          mcq_question: mq
        }
      ]
    )
  end

  def get_assessment(id) do
    Repo.get(Assessment, id)
  end

  def create_question(params, type, assessment_id)
    when is_binary(assessment_id) do
    assessment = Repo.get(Assessment, assessment_id)
    create_question(params, type, assessment)
  end

  def create_question(params, type, assessment) do
    Repo.transaction fn ->
      assessment = Repo.preload(assessment, :questions)
      questions = assessment.questions
      changeset = params
        |> build_question()
        |> put_assoc(:assessment, assessment)
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
    date = Timezone.convert(assessment.open_at, timezone)
    Timex.before?(date, Timex.now())
  end

  def prepare_workspace(id, question_order, student) when is_binary(id) do
    assessment = Repo.get(Assessment, id)
    if assessment == nil do
      {:error, :assessment_not_found}
    else
      prepare_workspace(assessment, question_order, student)
    end
  end

  def prepare_workspace(assessment, question_order, student) do
    # Ensure student attempted the assessment
    submission = find_submission(assessment, student)
    student = Repo.preload(student, :user)

    if submission == nil do
      {:error, :assessment_not_attempted}
    else
      question =
        case get_assessment_question(assessment, question_order, true) do
          {:ok, question} -> question
          {:error, _} -> nil
        end
      previous_question =
        case get_assessment_question(assessment, question_order - 1) do
          {:ok, question} -> question
          {:error, _} -> nil
        end
      next_question =
        case get_assessment_question(assessment, question_order + 1) do
          {:ok, question} -> question
          {:error, _} -> nil
        end

      # Need to pass answer only if programming question
      extra = if question.programming_question != nil do
        prepare_programming_question(
           question.programming_question,
           submission
        )
      else
        %{type: :mcq_question}
      end

      Map.merge(extra, %{
        student: student,
        assessment: assessment,
        question: question,
        next_question: next_question,
        previous_question: previous_question
      })
    end
  end

  def get_submission(id) do
    Repo.get(Submission, id)
    |> Repo.preload([
        assessment: [],
        student: [:user],
        programming_answers: [question: [:question]]
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

  def get_programming_answer(question, submission) do
    Repo.one(
      from answer in ProgrammingAnswer,
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
      question =
        if preload do
          Repo.preload(question,
            [
              mcq_question: [:choices],
              programming_question: [:test_cases]
            ]
          )
        else
          Repo.preload(question, [:mcq_question, :programming_question])
        end
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
    prefix = case assessment.type do
      :mission -> "mission"
      :sidequest -> "sidequest"
      :contest -> "contest"
      :path -> "path"
    end
    prefix <> "_" <> assessment.name <> "_q" <> order
  end

  def delete_mcq_choice(id) do
    mcq_choice = Repo.get!(MCQChoice, id)
    Repo.delete!(mcq_choice)
  end

  def update_grading(id, params, grader) do
    Repo.transaction fn ->
      submission = get_submission(id)
        |> Repo.preload(:programming_answers)
      changeset = build_grading(submission, params)

      # Get previous marks
      previous_marks = submission.programming_answers
        |> Enum.map(&(&1.marks))
        |> Enum.sum

      # Update Programming Answers
      for {_, ps} <- params["programming_answers"] do
        previous = Enum.find(
          submission.programming_answers,
          &(&1.id == String.to_integer(ps["id"]))
        )
        changeset = ProgrammingAnswer.changeset(previous, ps)
        Repo.update!(changeset)
      end

      total_marks = params["programming_answers"]
        |> Enum.map(fn {_, params} -> params["marks"] end)
        |> Enum.map(fn mark ->
          {parsed, _} = Float.parse(mark)
          parsed
        end)
        |> Enum.sum
      max_marks = submission.programming_answers
        |> Enum.map(&(&1.question.question.weight))
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

  def submit_mcq_choice(id, student) do
    mcq_choice = Repo.get!(MCQChoice, id)
      |> Repo.preload(:mcq_question)

    question = Repo.get!(Question, mcq_choice.mcq_question.question_id)

    path_submission = %PathSubmission{}
      |> PathSubmission.changeset(%{
          code: "",
          is_correct: mcq_choice.is_correct
       })
      |> put_assoc(:student, student)
      |> put_assoc(:mcq_choice, mcq_choice)
      |> put_assoc(:question, question)

    Repo.insert!(path_submission)

    mcq_choice
  end

  def submit_code(programming_question_id, code, student) do
    programming_question =
      Repo.get(ProgrammingQuestion, programming_question_id)
      |> Repo.preload(:test_cases)
    solution_header = programming_question.solution_header
    test_cases = programming_question.test_cases
    body = Poison.encode(%{
      header: solution_header,
      test_cases: Enum.map(test_cases, &(%{
        id: &1.id,
        code: &1.code,
        expected: &1.expected_result
      }))
    })
    headers = [
      {"Accept", "application/json"},
      {"Content-Type", "application/json"}
    ]
    response = HTTPotion.post("http://localhost:8080/submit", [
      body: body,
      headers: headers
    ])
    case response do
      %HTTPotion.Response{} ->
        {:ok, Poison.decode(response.body)}
      %HTTPotion.ErrorResponse{} ->
        {:error, response.message}
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
      |> Enum.filter(&(&1.type != :path && can_attempt?(&1, student.user)))
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
    {assessment.type, assessment.name}
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
    type = Atom.to_string(assessment.type)
    String.downcase(type) <> "-" <> assessment.name
  end

  defp create_concrete_question(question, type) do
    result = case type do
      "programming" -> create_blank_programming_question(question)
      _ -> create_blank_mcq_question(question)
    end
    case result do
      {:ok, _} -> question
      {:error, changeset} -> Repo.rollback(changeset)
    end
  end

  defp create_blank_programming_question(question) do
    build_programming_question(%{})
    |> put_assoc(:question, question)
    |> Repo.insert
  end

  defp create_blank_mcq_question(question) do
    build_mcq_question(%{})
    |> put_assoc(:question, question)
    |> Repo.insert
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

  defp prepare_mcq_question(mcq_question, submission) do
    mcq_question = Repo.preload(mcq_question, :choices)
    %{ type: :mcq_question }
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

      # 3. Update code readonly flag
      # If the submission is changed from submitted to attempting, set readonly
      # to false, and vice versa
      codes =
        from code in Code,
        join: answer in ProgrammingAnswer, on: answer.code_id == code.id,
        where: answer.submission_id == ^submission.id
      is_readonly = if new_status == :attempting, do: false, else: true
      Repo.update_all(codes, set: [is_readonly: is_readonly])
    end
  end

  def priority(id, delta) do
    changeset = change_assessment(id, %{})

    simple_update(Assessment, id,
      using: &Assessment.changeset/2,
      params: %{ priority: changeset.data.priority + delta })
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
