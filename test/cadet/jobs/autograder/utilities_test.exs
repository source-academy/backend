defmodule Cadet.Autograder.UtilitiesTest do
  use Cadet.DataCase

  alias Cadet.Autograder.Utilities

  describe "fetch_assessments_due_yesterday" do
    test "it only returns yesterday's assessments" do
      course = insert(:course)
      config = insert(:assessment_config, %{course: course})

      yesterday =
        insert_list(2, :assessment, %{
          is_published: true,
          open_at: Timex.shift(Timex.now(), days: -5),
          close_at: Timex.shift(Timex.now(), hours: -4),
          course: course,
          config: config
        })

      past =
        insert_list(2, :assessment, %{
          is_published: true,
          open_at: Timex.shift(Timex.now(), days: -5),
          close_at: Timex.shift(Timex.now(), days: -4),
          course: course,
          config: config
        })

      future =
        insert_list(2, :assessment, %{
          is_published: true,
          open_at: Timex.shift(Timex.now(), days: -3),
          close_at: Timex.shift(Timex.now(), days: 4),
          course: course,
          config: config
        })

      for assessment <- yesterday ++ past ++ future do
        insert_list(2, :programming_question, %{assessment: assessment})
      end

      assert get_assessments_ids(yesterday) ==
               get_assessments_ids(Utilities.fetch_assessments_due_yesterday())
    end

    test "it returns assessment questions in sorted order" do
      course = insert(:course)
      config = insert(:assessment_config, %{course: course})

      assessment =
        insert(:assessment, %{
          is_published: true,
          open_at: Timex.shift(Timex.now(), days: -5),
          close_at: Timex.shift(Timex.now(), hours: -4),
          course: course,
          config: config
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
      course = insert(:course)
      config = insert(:assessment_config, %{course: course})

      # Individual assessment
      assessment =
        insert(:assessment, %{
          is_published: true,
          course: course,
          config: config,
          max_team_size: 1
        })

      students = insert_list(5, :course_registration, %{role: :student, course: course})
      insert(:course_registration, %{course: build(:course), role: :student})

      # Team assessment
      team_assessment =
        insert(:assessment, %{
          is_published: true,
          course: course,
          config: config,
          max_team_size: 2
        })

      team_member1 = insert(:team_member, %{student: Enum.at(students, 0)})
      team_member2 = insert(:team_member, %{student: Enum.at(students, 1)})

      team1 =
        insert(:team, %{assessment: team_assessment, team_members: [team_member1, team_member2]})

      team_member3 = insert(:team_member, %{student: Enum.at(students, 2)})
      team_member4 = insert(:team_member, %{student: Enum.at(students, 3)})

      team2 =
        insert(:team, %{assessment: team_assessment, team_members: [team_member3, team_member4]})

      %{
        individual: %{students: students, assessment: assessment},
        team: %{
          teams: [team1, team2],
          assessment: team_assessment,
          teamless: [Enum.at(students, 4)]
        }
      }
    end

    test "it returns list of students with matching submissions for individual assessments", %{
      individual: %{students: students, assessment: assessment}
    } do
      submissions =
        Enum.map(
          students,
          &insert(:submission, %{assessment: assessment, student: &1, team: nil})
        )

      expected = Enum.map(submissions, &%{student_id: &1.student_id, submission_id: &1.id})

      results =
        assessment.id
        |> Utilities.fetch_submissions(assessment.course_id)
        |> Enum.map(&%{student_id: &1.student_id, submission_id: &1.submission.id})

      assert results == expected
    end

    test "it returns list of students without matching submissions for individual assessments", %{
      individual: %{students: students, assessment: assessment}
    } do
      expected_student_ids = Enum.map(students, & &1.id)

      results = Utilities.fetch_submissions(assessment.id, assessment.course_id)

      assert results |> Enum.map(& &1.student_id) |> Enum.sort() ==
               Enum.sort(expected_student_ids)

      assert results |> Enum.map(& &1.submission) |> Enum.uniq() == [nil]
    end

    test "it returns list of students both with and without matching submissions for team assessments",
         %{
           team: %{teams: teams, assessment: assessment, teamless: teamless}
         } do
      submissions =
        Enum.map(
          teams,
          &%{
            team_id: &1.id,
            submission: insert(:submission, %{assessment: assessment, team: &1, student: nil})
          }
        )

      expected =
        teams
        |> Enum.flat_map(& &1.team_members)
        |> Enum.map(
          &%{
            student_id: &1.student_id,
            submission_id:
              Enum.find(submissions, fn s -> s.team_id == &1.team_id end).submission.id
          }
        )

      expected = expected ++ Enum.map(teamless, &%{student_id: &1.id, submission_id: nil})

      results =
        assessment.id
        |> Utilities.fetch_submissions(assessment.course_id)
        |> Enum.map(
          &%{
            student_id: &1.student_id,
            submission_id: if(&1.submission, do: &1.submission.id, else: nil)
          }
        )

      assert results == expected
    end
  end

  defp get_assessments_ids(assessments) do
    assessments |> Enum.map(fn a -> a.id end) |> Enum.sort()
  end
end
