defmodule Cadet.Test.Seeds do
  @moduledoc """
  This module contains functions that seed more complex setups into the DB for tests.
  """
  import Cadet.Factory

  def assessments do
    if Application.get_env(:cadet, :environment) == :test do
      # User and Group
      avenger = insert(:user, %{name: "avenger", role: :staff})
      mentor = insert(:user, %{name: "mentor", role: :staff})
      group = insert(:group, %{leader: avenger, mentor: mentor})
      students = insert_list(5, :student, %{group: group})
      admin = insert(:user, %{name: "admin", role: :admin})
      Enum.each([avenger, mentor] ++ students, &insert(:nusnet_id, %{user: &1}))

      users = %{
        avenger: avenger,
        mentor: mentor,
        group: group,
        students: students,
        admin: admin
      }

      assessments =
        Enum.reduce(
          Cadet.Assessments.AssessmentType.__enum_map__(),
          %{},
          fn type, acc -> Map.put(acc, type, build_assessment(type, students)) end
        )

      %{
        users: users,
        assessments: assessments
      }
    end
  end

  defp build_assessment(assessment_type, students) do
    assessment = insert(:assessment, %{type: assessment_type, is_published: true})

    programming_questions =
      Enum.map(1..3, fn id ->
        insert(:question, %{
          display_order: id,
          type: :programming,
          library: if(Enum.random(0..2) == 0, do: build(:library)),
          question: build(:programming_question),
          assessment: assessment,
          max_xp: 200
        })
      end)

    mcq_questions =
      Enum.map(4..6, fn id ->
        insert(:question, %{
          display_order: id,
          type: :multiple_choice,
          question: build(:mcq_question),
          assessment: assessment,
          max_xp: 40
        })
      end)

    submissions =
      students
      |> Enum.take(2)
      |> Enum.map(&insert(:submission, %{assessment: assessment, student: &1}))

    # Programming Answers
    programming_answers =
      for submission <- submissions,
          question <- programming_questions do
        insert(:answer, %{
          xp: 200,
          question: question,
          submission: submission,
          answer: build(:programming_answer)
        })
      end

    # MCQ Answers
    mcq_answers =
      for submission <- submissions,
          question <- mcq_questions do
        insert(:answer, %{
          xp: 200,
          question: question,
          submission: submission,
          answer: build(:mcq_answer)
        })
      end

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
