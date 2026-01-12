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
      # Course
      course1 = insert(:course)
      course2 = insert(:course, %{course_name: "Algorithm", course_short_name: "CS2040S"})
      # Users
      avenger1 =
        insert(:user, %{
          name: "avenger",
          latest_viewed_course: course1,
          email: "avenger1@gmail.com"
        })

      avenger2 =
        insert(:user, %{
          name: "avenger2",
          latest_viewed_course: course1,
          email: "avenger2@gmail.com"
        })

      admin1 = insert(:user, %{name: "admin", latest_viewed_course: course1})

      studenta1admin2 = insert(:user, %{name: "student a", latest_viewed_course: course1})

      studentb1 = insert(:user, %{latest_viewed_course: course1})
      studentc1 = insert(:user, %{latest_viewed_course: course1})
      student_attempted = insert(:user, %{latest_viewed_course: course1})
      student_submitted = insert(:user, %{latest_viewed_course: course1})
      student_graded = insert(:user, %{latest_viewed_course: course1})
      student_different_group = insert(:user, %{latest_viewed_course: course1})
      student_grading_published = insert(:user, %{latest_viewed_course: course1})

      # CourseRegistration and Group
      avenger1_cr = insert(:course_registration, %{user: avenger1, course: course1, role: :staff})
      avenger2_cr = insert(:course_registration, %{user: avenger2, course: course1, role: :staff})
      admin1_cr = insert(:course_registration, %{user: admin1, course: course1, role: :admin})
      group = insert(:group, %{leader: avenger1_cr})
      group2 = insert(:group, %{leader: avenger2_cr})

      student1a_cr =
        insert(:course_registration, %{
          user: studenta1admin2,
          course: course1,
          role: :student,
          group: group
        })

      student1b_cr =
        insert(:course_registration, %{
          user: studentb1,
          course: course1,
          role: :student,
          group: group
        })

      student1c_cr =
        insert(:course_registration, %{
          user: studentc1,
          course: course1,
          role: :student,
          group: group
        })

      student_attempted_cr =
        insert(:course_registration, %{
          user: student_attempted,
          course: course1,
          role: :student,
          group: group
        })

      student_submitted_cr =
        insert(:course_registration, %{
          user: student_submitted,
          course: course1,
          role: :student,
          group: group
        })

      student_graded_cr =
        insert(:course_registration, %{
          user: student_graded,
          course: course1,
          role: :student,
          group: group
        })

      student_different_group_cr =
        insert(:course_registration, %{
          user: student_different_group,
          course: course1,
          role: :student,
          group: group2
        })

      student_grading_published_cr =
        insert(:course_registration, %{
          user: student_grading_published,
          course: course1,
          role: :student,
          group: group
        })

      students = [
        student1a_cr,
        student1b_cr,
        student1c_cr,
        student_attempted_cr,
        student_submitted_cr,
        student_graded_cr,
        student_different_group_cr,
        student_grading_published_cr
      ]

      # {student_cr, submission_status, is_graded, is_grading_published, avenger}
      students_with_assessment_info = [
        {student1a_cr, :attempting, false, false, avenger1_cr},
        {student1b_cr, :attempting, false, false, avenger1_cr},
        {student1c_cr, :attempting, false, false, avenger1_cr},
        {student_attempted_cr, :attempted, false, false, avenger1_cr},
        {student_submitted_cr, :submitted, false, false, avenger1_cr},
        {student_graded_cr, :submitted, true, false, avenger1_cr},
        {student_different_group_cr, :attempting, false, false, avenger2_cr},
        {student_grading_published_cr, :submitted, true, true, avenger1_cr}
      ]

      _admin2cr =
        insert(:course_registration, %{user: studenta1admin2, course: course2, role: :admin})

      assessment_configs = [
        insert(:assessment_config, %{course: course1, order: 1, type: "mission"}),
        insert(:assessment_config, %{course: course1, order: 2}),
        insert(:assessment_config, %{
          course: course1,
          order: 3,
          show_grading_summary: false,
          is_manually_graded: false,
          type: "path"
        }),
        insert(:assessment_config, %{course: course1, order: 4}),
        insert(:assessment_config, %{
          course: course1,
          order: 5,
          type: "practical"
        })
      ]

      # 1..5 |> Enum.map(&insert(:assessment_config, %{course: course1, order: &1}))

      assessments =
        assessment_configs
        |> Enum.reduce(
          %{},
          fn config, acc ->
            Map.put(
              acc,
              config.type,
              insert_assessments(config, students_with_assessment_info, course1)
            )
          end
        )

      %{
        courses: %{
          course1: course1,
          course2: course2
        },
        course_regs: %{
          avenger1_cr: avenger1_cr,
          avenger2_cr: avenger2_cr,
          group: group,
          group2: group2,
          students: students,
          admin1_cr: admin1_cr
        },
        role_crs: %{
          staff: avenger1_cr,
          student: student1a_cr,
          admin: admin1_cr
        },
        assessment_configs: assessment_configs,
        assessments: assessments,
        students_with_assessment_info: students_with_assessment_info,
        student_grading_published: student_grading_published_cr
      }
    end
  end

  defp insert_assessments(assessment_config, students, course) do
    assessment =
      insert(:assessment, %{course: course, config: assessment_config, is_published: true})

    contest_assessment =
      insert(:assessment, %{course: course, config: assessment_config, is_published: true})

    programming_questions =
      Enum.map(1..3, fn id ->
        insert(:programming_question, %{
          display_order: id,
          assessment: assessment,
          max_xp: 1000,
          show_solution: assessment.config.type == "path",
          question: build(:programming_question_content)
        })
      end)

    mcq_questions =
      Enum.map(4..6, fn id ->
        insert(:mcq_question, %{
          display_order: id,
          assessment: assessment,
          max_xp: 500,
          show_solution: assessment.config.type == "path"
        })
      end)

    voting_questions =
      Enum.map(7..9, fn id ->
        insert(:voting_question, %{
          display_order: id,
          assessment: assessment,
          max_xp: 100,
          show_solution: assessment.config.type == "path",
          question: build(:voting_question_content, contest_number: contest_assessment.number)
        })
      end)

    submissions_with_grader =
      students
      |> Enum.map(fn {student, submission_status, is_graded, is_grading_published, avenger} ->
        grader = if is_graded, do: avenger, else: nil

        {grader,
         insert(:submission, %{
           assessment: assessment,
           student: student,
           status: submission_status,
           is_grading_published: is_grading_published
         })}
      end)

    submissions = Enum.map(submissions_with_grader, fn {_, submission} -> submission end)
    # Programming Answers
    programming_answers =
      Enum.map(submissions_with_grader, fn {grader, submission} ->
        Enum.map(programming_questions, fn question ->
          insert(:answer, %{
            xp: 800,
            question: question,
            submission: submission,
            answer: build(:programming_answer),
            grader: grader
          })
        end)
      end)

    mcq_answers =
      Enum.map(submissions_with_grader, fn {grader, submission} ->
        Enum.map(mcq_questions, fn question ->
          insert(:answer, %{
            xp: 500,
            question: question,
            submission: submission,
            answer: build(:mcq_answer),
            grader: grader
          })
        end)
      end)

    voting_answers =
      Enum.map(submissions_with_grader, fn {grader, submission} ->
        Enum.map(voting_questions, fn question ->
          insert(:answer, %{
            xp: 100,
            question: question,
            submission: submission,
            answer: build(:voting_answer),
            grader: grader
          })
        end)
      end)

    %{
      assessment: assessment,
      programming_questions: programming_questions,
      mcq_questions: mcq_questions,
      voting_questions: voting_questions,
      submissions: submissions,
      programming_answers: programming_answers,
      mcq_answers: mcq_answers,
      voting_answers: voting_answers
    }
  end
end
