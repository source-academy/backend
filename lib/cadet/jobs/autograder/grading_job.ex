defmodule Cadet.Autograder.GradingJob do
  @moduledoc """
  This module contains logic for finding answers to be graded and
  processing/dispatching them as appropriate
  """
  use Cadet, :context

  import Ecto.Query

  require Logger

  alias Cadet.Accounts.{Team, TeamMember}
  alias Cadet.Assessments
  alias Cadet.Assessments.{Answer, Assessment, Question, Submission, SubmissionVotes}
  alias Cadet.Autograder.Utilities
  alias Cadet.Courses.AssessmentConfig
  alias Cadet.Jobs.Log

  def close_and_make_empty_submission(assessment = %Assessment{id: id}) do
    id
    |> Utilities.fetch_submissions(assessment.course_id)
    |> Enum.map(fn %{student_id: student_id, submission: submission} ->
      if submission do
        update_submission_status_to_submitted(submission)
      else
        insert_empty_submission(%{student_id: student_id, assessment: assessment})
      end
    end)
  end

  def grade_all_due_yesterday do
    # 1435 = 1 day - 5 minutes
    if Log.log_execution("grading_job", Timex.Duration.from_minutes(1435)) do
      Logger.info("Started autograding")

      for assessment <- Utilities.fetch_assessments_due_yesterday() do
        assessment
        |> close_and_make_empty_submission()
        |> Enum.each(&grade_individual_submission(&1, assessment))
      end
    else
      Logger.info("Not grading - raced")
    end
  end

  @doc """
  Exposed as public function in case future mix tasks are needed to regrade
  certain submissions. Manual grading can also be triggered from iex with this
  function.

  Takes in submission to be graded. Submission will be graded regardless of its
  assessment's close_by date or submission status.

  Every answer will be regraded regardless of its current autograding status.
  """
  def force_grade_individual_submission(submission = %Submission{}, overwrite \\ false) do
    assessment =
      if Ecto.assoc_loaded?(submission.assessment) do
        submission.assessment
      else
        submission |> Repo.preload(:assessment) |> Map.get(:assessment)
      end

    assessment = preprocess_assessment_for_grading(assessment)
    grade_individual_submission(submission, assessment, true, overwrite)
  end

  # This function requires that assessment questions are already preloaded in sorted
  # order for autograding to function correctly.
  defp grade_individual_submission(
         %Submission{id: submission_id},
         %Assessment{questions: questions},
         regrade \\ false,
         overwrite \\ false
       ) do
    answers =
      Answer
      |> where(submission_id: ^submission_id)
      |> order_by(:question_id)
      |> Repo.all()

    grade_submission_question_answer_lists(
      submission_id,
      questions,
      answers,
      regrade,
      overwrite
    )
  end

  defp preprocess_assessment_for_grading(assessment = %Assessment{}) do
    if Ecto.assoc_loaded?(assessment.questions) do
      Utilities.sort_assessment_questions(assessment)
    else
      questions =
        Question
        |> where(assessment_id: ^assessment.id)
        |> order_by(:id)
        |> Repo.all()

      Map.put(assessment, :questions, questions)
    end
  end

  defp insert_empty_submission(%{student_id: student_id, assessment: assessment}) do
    if Assessments.is_team_assessment?(assessment.id) do
      # Get current team if any
      team =
        Team
        |> where(assessment_id: ^assessment.id)
        |> join(:inner, [t], tm in assoc(t, :team_members))
        |> where([_, tm], tm.student_id == ^student_id)
        |> Repo.one()

      team =
        if team do
          team
        else
          # Student is not in any team
          # Create new team just for the student
          team =
            %Team{}
            |> Team.changeset(%{
              assessment_id: assessment.id
            })
            |> Repo.insert!()

          %TeamMember{}
          |> TeamMember.changeset(%{
            team_id: team.id,
            student_id: student_id
          })
          |> Repo.insert!()

          team
        end

      find_or_create_team_submission(team.id, assessment)
    else
      # Individual assessment
      %Submission{}
      |> Submission.changeset(%{
        student_id: student_id,
        assessment: assessment,
        status: :submitted
      })
      |> Repo.insert!()
    end
  end

  defp find_or_create_team_submission(team_id, assessment) when is_ecto_id(team_id) do
    submission =
      Submission
      |> where(team_id: ^team_id, assessment_id: ^assessment.id)
      |> Repo.one()

    if submission do
      submission
    else
      %Submission{}
      |> Submission.changeset(%{
        team_id: team_id,
        assessment: assessment,
        status: :submitted
      })
      |> Repo.insert!()
    end
  end

  defp update_submission_status_to_submitted(submission = %Submission{status: status}) do
    if status != :submitted do
      Cadet.Accounts.Notifications.write_notification_when_student_submits(submission)

      submission
      |> Submission.changeset(%{status: :submitted})
      |> Repo.update!()
    else
      submission
    end
  end

  def grade_answer(answer = %Answer{}, question = %Question{type: type}, overwrite \\ false) do
    case type do
      :programming ->
        Utilities.dispatch_programming_answer(answer, question, overwrite)

      :mcq ->
        grade_mcq_answer(answer, question)

      :voting ->
        grade_voting_answer(answer, question)
    end
  end

  defp grade_voting_answer(answer = %Answer{submission_id: submission_id}, question = %Question{}) do
    is_nil_entries =
      Submission
      |> where(id: ^submission_id)
      |> join(:inner, [s], sv in SubmissionVotes,
        on: sv.voter_id == s.student_id and sv.question_id == ^question.id
      )
      |> where([_, sv], is_nil(sv.score))
      |> Repo.exists?()

    xp = if is_nil_entries, do: 0, else: question.max_xp

    answer
    |> Answer.autograding_changeset(%{
      xp_adjustment: 0,
      xp: xp,
      autograding_status: :success
    })
    |> Repo.update()
  end

  defp grade_mcq_answer(answer = %Answer{}, question = %Question{question: question_content}) do
    correct_choice =
      question_content["choices"]
      |> Enum.find(&Map.get(&1, "is_correct"))
      |> Map.get("choice_id")

    correct? = answer.answer["choice_id"] == correct_choice
    xp = if correct?, do: question.max_xp, else: 0

    answer
    |> Answer.autograding_changeset(%{
      xp_adjustment: 0,
      xp: xp,
      autograding_status: :success
    })
    |> Repo.update()
  end

  defp insert_empty_answer(
         submission_id,
         %Question{id: question_id, type: question_type}
       )
       when is_ecto_id(submission_id) do
    answer_content =
      case question_type do
        :programming -> %{code: "// Question was left blank by the student."}
        :mcq -> %{choice_id: 0}
        :voting -> %{completed: false}
      end

    %Answer{}
    |> Answer.changeset(%{
      answer: answer_content,
      question_id: question_id,
      submission_id: submission_id,
      type: question_type
    })
    |> Answer.autograding_changeset(%{grade: 0, autograding_status: :success})
    |> Repo.insert()
  end

  # Two finger walk down question and answer lists.
  # Both lists MUST be pre-sorted by id and question_id respectively
  defp grade_submission_question_answer_lists(
         submission_id,
         questions,
         answers,
         regrade,
         overwrite
       )

  defp grade_submission_question_answer_lists(
         submission_id,
         [question = %Question{} | question_tail],
         answers = [answer = %Answer{} | answer_tail],
         regrade,
         overwrite
       )
       when is_boolean(regrade) and is_boolean(overwrite) and is_ecto_id(submission_id) do
    if question.id == answer.question_id do
      if regrade || answer.autograding_status in [:none, :failed] do
        grade_answer(answer, question, overwrite)
      end

      grade_submission_question_answer_lists(
        submission_id,
        question_tail,
        answer_tail,
        regrade,
        overwrite
      )
    else
      insert_empty_answer(submission_id, question)

      grade_submission_question_answer_lists(
        submission_id,
        question_tail,
        answers,
        regrade,
        overwrite
      )
    end
  end

  defp grade_submission_question_answer_lists(
         submission_id,
         [question = %Question{} | question_tail],
         [],
         regrade,
         overwrite
       )
       when is_boolean(regrade) and is_boolean(overwrite) and is_ecto_id(submission_id) do
    insert_empty_answer(submission_id, question)

    grade_submission_question_answer_lists(
      submission_id,
      question_tail,
      [],
      regrade,
      overwrite
    )
  end

  defp grade_submission_question_answer_lists(submission_id, [], [], _, _) do
    submission = Repo.get(Submission, submission_id)
    assessment = Repo.get(Assessment, submission.assessment_id)
    assessment_config = Repo.get_by(AssessmentConfig, id: assessment.config_id)
    is_grading_auto_published = assessment_config.is_grading_auto_published
    is_manually_graded = assessment_config.is_manually_graded

    if Assessments.is_fully_autograded?(submission_id) and is_grading_auto_published and
         not is_manually_graded do
      Assessments.publish_grading(submission_id)
    end
  end
end
