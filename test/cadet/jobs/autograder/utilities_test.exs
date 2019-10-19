defmodule Cadet.Autograder.UtilitiesTest do
  use Cadet.DataCase

  alias Cadet.Assessments.AssessmentType
  alias Cadet.Autograder.Utilities

  describe "fetch_assessments_due_yesterday" do
    test "it only returns yesterday's assessments" do
      yesterday =
        insert_list(2, :assessment, %{
          is_published: true,
          open_at: Timex.shift(Timex.now(), days: -5),
          close_at: Timex.shift(Timex.now(), hours: -4),
          type: :mission
        })

      past =
        insert_list(2, :assessment, %{
          is_published: true,
          open_at: Timex.shift(Timex.now(), days: -5),
          close_at: Timex.shift(Timex.now(), days: -4),
          type: :mission
        })

      future =
        insert_list(2, :assessment, %{
          is_published: true,
          open_at: Timex.shift(Timex.now(), days: -3),
          close_at: Timex.shift(Timex.now(), days: 4),
          type: :mission
        })

      for assessment <- yesterday ++ past ++ future do
        insert_list(2, :programming_question, %{assessment: assessment})
      end

      assert get_assessments_ids(yesterday) ==
               get_assessments_ids(Utilities.fetch_assessments_due_yesterday())
    end

    test "it returns assessment questions in sorted order" do
      assessment =
        insert(:assessment, %{
          is_published: true,
          open_at: Timex.shift(Timex.now(), days: -5),
          close_at: Timex.shift(Timex.now(), hours: -4),
          type: :mission
        })

      insert_list(5, :programming_question, %{assessment: assessment})

      [assessment | _] = Utilities.fetch_assessments_due_yesterday()

      assert assessment.questions

      for [first, second] <- Enum.chunk_every(assessment.questions, 2, 1, :discard) do
        assert first.id < second.id
      end
    end
  end

  describe "fetch_submissions" do
    setup do
      assessment = insert(:assessment, %{is_published: true})
      students = insert_list(5, :user, %{role: :student})
      %{students: students, assessment: assessment}
    end

    test "it returns list of students with matching submissions", %{
      students: students,
      assessment: assessment
    } do
      submissions =
        Enum.map(students, &insert(:submission, %{assessment: assessment, student: &1}))

      expected = Enum.map(submissions, &%{student_id: &1.student_id, submission_id: &1.id})

      results =
        assessment.id
        |> Utilities.fetch_submissions()
        |> Enum.map(&%{student_id: &1.student_id, submission_id: &1.submission.id})

      assert results == expected
    end

    test "it returns list of students with without matching submissions", %{
      students: students,
      assessment: assessment
    } do
      expected_student_ids = Enum.map(students, & &1.id)

      results = Utilities.fetch_submissions(assessment.id)
      assert Enum.map(results, & &1.student_id) == expected_student_ids
      assert results |> Enum.map(& &1.submission) |> Enum.uniq() == [nil]
    end
  end

  defp get_assessments_ids(assessments) do
    assessments |> Enum.map(fn a -> a.id end) |> Enum.sort()
  end
end
