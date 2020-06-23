# Script for populating the database. You can run it as:
#
#     mix run priv/repo/seeds.exs
#
# Inside the script, you can read and write to any of your
# repositories directly:
#
#     Cadet.Repo.insert!(%Cadet.SomeSchema{})
#
# We recommend using the bang functions (`insert!`, `update!`
# and so on) as they will fail if something goes wrong.
import Cadet.Factory
alias Cadet.Assessments.SubmissionStatus

# insert default source version
Cadet.Repo.insert!(%Cadet.Chapters.Chapter{chapterno: 1, variant: "default"})

if Cadet.Env.env() == :dev do
  # User and Group
  avenger = insert(:user, %{name: "avenger", role: :staff})
  mentor = insert(:user, %{name: "mentor", role: :staff})
  group = insert(:group, %{leader: avenger, mentor: mentor})
  students = insert_list(5, :student, %{group: group})
  admin = insert(:user, %{name: "admin", role: :admin})

  # Achievements 
  for x <- 1..5 do 
    insert(:achievement, %{inferencer_id: x})
  end 

  # Assessments
  for _ <- 1..5 do
    assessment = insert(:assessment, %{is_published: true})

    programming_questions =
      insert_list(3, :programming_question, %{
        assessment: assessment,
        max_grade: 200,
        max_xp: 1_000
      })

    mcq_questions =
      insert_list(3, :mcq_question, %{
        assessment: assessment,
        max_grade: 40,
        max_xp: 500
      })

    submissions =
      students
      |> Enum.take(2)
      |> Enum.map(
        &insert(:submission, %{
          assessment: assessment,
          student: &1,
          status: Enum.random(SubmissionStatus.__enum_map__())
        })
      )

    # Programming Answers
    for submission <- submissions,
        question <- programming_questions do
      insert(:answer, %{
        grade: Enum.random(0..200),
        xp: Enum.random(0..1_000),
        question: question,
        submission: submission,
        answer: build(:programming_answer)
      })
    end

    # MCQ Answers
    for submission <- submissions,
        question <- mcq_questions do
      insert(:answer, %{
        grade: Enum.random(0..40),
        xp: Enum.random(0..500),
        question: question,
        submission: submission,
        answer: build(:mcq_answer)
      })
    end

    # Notifications
    for submission <- submissions do
      case submission.status do
        :submitted ->
          insert(:notification, %{
            type: :submitted,
            read: false,
            user_id: avenger.id,
            submission_id: submission.id,
            assessment_id: assessment.id
          })

        _ ->
          nil
      end
    end

    for student <- students do
      insert(:notification, %{
        type: :new,
        user_id: student.id,
        assessment_id: assessment.id
      })
    end
  end
end
