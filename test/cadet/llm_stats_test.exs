defmodule Cadet.LLMStatsTest do
  use Cadet.DataCase

  alias Cadet.LLMStats
  alias Cadet.LLMStats.LLMUsageLog

  describe "log_usage/1" do
    test "inserts a usage log record" do
      course = insert(:course)
      assessment = insert(:assessment, course: course)
      question = insert(:question, assessment: assessment, display_order: 1)
      student = insert(:course_registration, course: course, role: :student)
      submission = insert(:submission, assessment: assessment, student: student)
      answer = insert(:answer, submission: submission, question: question)
      user = insert(:user)

      attrs = %{
        course_id: course.id,
        assessment_id: assessment.id,
        question_id: question.id,
        answer_id: answer.id,
        submission_id: submission.id,
        user_id: user.id
      }

      assert {:ok, usage_log} = LLMStats.log_usage(attrs)
      assert usage_log.course_id == course.id
      assert usage_log.assessment_id == assessment.id
      assert usage_log.question_id == question.id
      assert usage_log.answer_id == answer.id
      assert usage_log.submission_id == submission.id
      assert usage_log.user_id == user.id

      assert Repo.get(LLMUsageLog, usage_log.id)
    end
  end

  describe "get_assessment_statistics/2" do
    test "returns aggregate and per-question statistics scoped to assessment" do
      course = insert(:course)
      assessment = insert(:assessment, course: course)
      question_1 = insert(:question, assessment: assessment, display_order: 1)
      question_2 = insert(:question, assessment: assessment, display_order: 2)

      student_1 = insert(:course_registration, course: course, role: :student)
      student_2 = insert(:course_registration, course: course, role: :student)
      submission_1 = insert(:submission, assessment: assessment, student: student_1)
      submission_2 = insert(:submission, assessment: assessment, student: student_2)

      answer_11 = insert(:answer, submission: submission_1, question: question_1)
      answer_12 = insert(:answer, submission: submission_1, question: question_2)
      answer_21 = insert(:answer, submission: submission_2, question: question_1)

      user_1 = insert(:user)
      user_2 = insert(:user)

      assert {:ok, _} =
               LLMStats.log_usage(%{
                 course_id: course.id,
                 assessment_id: assessment.id,
                 question_id: question_1.id,
                 answer_id: answer_11.id,
                 submission_id: submission_1.id,
                 user_id: user_1.id
               })

      assert {:ok, _} =
               LLMStats.log_usage(%{
                 course_id: course.id,
                 assessment_id: assessment.id,
                 question_id: question_1.id,
                 answer_id: answer_11.id,
                 submission_id: submission_1.id,
                 user_id: user_1.id
               })

      assert {:ok, _} =
               LLMStats.log_usage(%{
                 course_id: course.id,
                 assessment_id: assessment.id,
                 question_id: question_1.id,
                 answer_id: answer_21.id,
                 submission_id: submission_2.id,
                 user_id: user_2.id
               })

      assert {:ok, _} =
               LLMStats.log_usage(%{
                 course_id: course.id,
                 assessment_id: assessment.id,
                 question_id: question_2.id,
                 answer_id: answer_12.id,
                 submission_id: submission_1.id,
                 user_id: user_1.id
               })

      other_course = insert(:course)
      other_assessment = insert(:assessment, course: other_course)
      other_question = insert(:question, assessment: other_assessment, display_order: 1)
      other_student = insert(:course_registration, course: other_course, role: :student)
      other_submission = insert(:submission, assessment: other_assessment, student: other_student)
      other_answer = insert(:answer, submission: other_submission, question: other_question)

      assert {:ok, _} =
               LLMStats.log_usage(%{
                 course_id: other_course.id,
                 assessment_id: other_assessment.id,
                 question_id: other_question.id,
                 answer_id: other_answer.id,
                 submission_id: other_submission.id,
                 user_id: user_1.id
               })

      stats = LLMStats.get_assessment_statistics(course.id, assessment.id)

      assert stats.total_uses == 4
      assert stats.unique_submissions == 2
      assert stats.unique_users == 2

      assert [q1_stats, q2_stats] = stats.questions

      assert q1_stats.question_id == question_1.id
      assert q1_stats.display_order == 1
      assert q1_stats.total_uses == 3
      assert q1_stats.unique_submissions == 2
      assert q1_stats.unique_users == 2

      assert q2_stats.question_id == question_2.id
      assert q2_stats.display_order == 2
      assert q2_stats.total_uses == 1
      assert q2_stats.unique_submissions == 1
      assert q2_stats.unique_users == 1
    end
  end

  describe "get_question_statistics/3" do
    test "returns statistics scoped to one question" do
      course = insert(:course)
      assessment = insert(:assessment, course: course)
      question_1 = insert(:question, assessment: assessment, display_order: 1)
      question_2 = insert(:question, assessment: assessment, display_order: 2)

      student_1 = insert(:course_registration, course: course, role: :student)
      student_2 = insert(:course_registration, course: course, role: :student)
      submission_1 = insert(:submission, assessment: assessment, student: student_1)
      submission_2 = insert(:submission, assessment: assessment, student: student_2)

      answer_11 = insert(:answer, submission: submission_1, question: question_1)
      answer_21 = insert(:answer, submission: submission_2, question: question_1)
      answer_12 = insert(:answer, submission: submission_1, question: question_2)

      user_1 = insert(:user)
      user_2 = insert(:user)

      assert {:ok, _} =
               LLMStats.log_usage(%{
                 course_id: course.id,
                 assessment_id: assessment.id,
                 question_id: question_1.id,
                 answer_id: answer_11.id,
                 submission_id: submission_1.id,
                 user_id: user_1.id
               })

      assert {:ok, _} =
               LLMStats.log_usage(%{
                 course_id: course.id,
                 assessment_id: assessment.id,
                 question_id: question_1.id,
                 answer_id: answer_11.id,
                 submission_id: submission_1.id,
                 user_id: user_1.id
               })

      assert {:ok, _} =
               LLMStats.log_usage(%{
                 course_id: course.id,
                 assessment_id: assessment.id,
                 question_id: question_1.id,
                 answer_id: answer_21.id,
                 submission_id: submission_2.id,
                 user_id: user_2.id
               })

      assert {:ok, _} =
               LLMStats.log_usage(%{
                 course_id: course.id,
                 assessment_id: assessment.id,
                 question_id: question_2.id,
                 answer_id: answer_12.id,
                 submission_id: submission_1.id,
                 user_id: user_1.id
               })

      stats = LLMStats.get_question_statistics(course.id, assessment.id, question_1.id)

      assert stats.total_uses == 3
      assert stats.unique_submissions == 2
      assert stats.unique_users == 2
    end
  end

  describe "get_feedback/3" do
    test "filters by question_id when provided" do
      course = insert(:course)
      assessment = insert(:assessment, course: course)
      question_1 = insert(:question, assessment: assessment, display_order: 1)
      question_2 = insert(:question, assessment: assessment, display_order: 2)
      user_1 = insert(:user, name: "Alice")
      user_2 = insert(:user, name: "Bob")

      assert {:ok, _} =
               LLMStats.submit_feedback(%{
                 course_id: course.id,
                 assessment_id: assessment.id,
                 question_id: question_1.id,
                 user_id: user_1.id,
                 rating: 5,
                 body: "Very helpful"
               })

      assert {:ok, _} =
               LLMStats.submit_feedback(%{
                 course_id: course.id,
                 assessment_id: assessment.id,
                 question_id: question_2.id,
                 user_id: user_2.id,
                 rating: 3,
                 body: "Could be clearer"
               })

      unfiltered = LLMStats.get_feedback(course.id, assessment.id)
      filtered = LLMStats.get_feedback(course.id, assessment.id, question_1.id)

      assert Enum.count(unfiltered) == 2
      assert Enum.count(filtered) == 1

      assert [%{question_id: qid, user_name: "Alice", rating: 5, body: "Very helpful"}] = filtered
      assert qid == question_1.id
    end
  end
end
