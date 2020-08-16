defmodule Cadet.Test.Seeds do
  @moduledoc """
  This module contains functions that seed more complex setups into the DB for tests.
  """
  import Cadet.Factory

  @doc """
  This sets up the common assessments environment by inserting relevant entries into the DB.
  Returns a map of the following format:
  %{
    accounts: %{
      avenger: avenger,
      mentor: mentor,
      group: group,
      students: students,
      admin: admin
    },
    users: %{
      staff: avenger,
      student: List.first(students),
      admin: admin
    },
    assessments: %{
      path: %{
        assessment: assessment,
        programming_questions: programming_questions,
        mcq_questions: mcq_questions,
        submissions: submissions,
        programming_answers: programming_answers,
        mcq_answers: mcq_answers
      },
      mission: ...,
      contest: ...,
      sidequest: ...
    }
  }
  """

  def assessments do
    if Cadet.Env.env() == :test do
      # User and Group
      avenger = insert(:user, %{name: "avenger", role: :staff})
      mentor = insert(:user, %{name: "mentor", role: :staff})
      group = insert(:group, %{leader: avenger, mentor: mentor})
      students = insert_list(5, :student, %{group: group})
      admin = insert(:user, %{name: "admin", role: :admin})

      assessments =
        Enum.reduce(
          Cadet.Assessments.Assessment.assessment_types(),
          %{},
          fn type, acc -> Map.put(acc, type, insert_assessments(type, students)) end
        )

      %{
        accounts: %{
          avenger: avenger,
          mentor: mentor,
          group: group,
          students: students,
          admin: admin
        },
        users: %{
          staff: avenger,
          student: List.first(students),
          admin: admin
        },
        assessments: assessments
      }
    end
  end

  defp insert_assessments(assessment_type, students) do
    assessment = insert(:assessment, %{type: assessment_type, is_published: true})

    programming_questions =
      Enum.map(1..3, fn id ->
        insert(:programming_question, %{
          display_order: id,
          assessment: assessment,
          max_grade: 200,
          max_xp: 1000
        })
      end)

    mcq_questions =
      Enum.map(4..6, fn id ->
        insert(:mcq_question, %{
          display_order: id,
          assessment: assessment,
          max_grade: 40,
          max_xp: 500
        })
      end)

    submissions =
      students
      |> Enum.take(2)
      |> Enum.map(&insert(:submission, %{assessment: assessment, student: &1}))

    # Programming Answers
    programming_answers =
      Enum.map(submissions, fn submission ->
        Enum.map(programming_questions, fn question ->
          insert(:answer, %{
            grade: 200,
            xp: 1000,
            question: question,
            submission: submission,
            answer: build(:programming_answer)
          })
        end)
      end)

    mcq_answers =
      Enum.map(submissions, fn submission ->
        Enum.map(mcq_questions, fn question ->
          insert(:answer, %{
            grade: 40,
            xp: 500,
            question: question,
            submission: submission,
            answer: build(:mcq_answer)
          })
        end)
      end)

    %{
      assessment: assessment,
      programming_questions: programming_questions,
      mcq_questions: mcq_questions,
      submissions: submissions,
      programming_answers: programming_answers,
      mcq_answers: mcq_answers
    }
  end
end
