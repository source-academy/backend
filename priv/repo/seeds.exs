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

if Application.get_env(:cadet, :environment) == :dev do
  # User and Group
  avenger = insert(:user, %{name: "avenger", role: :staff})
  mentor = insert(:user, %{name: "mentor", role: :staff})
  group = insert(:group, %{leader: avenger, mentor: mentor})
  students = insert_list(5, :student, %{group: group})
  admin = insert(:user, %{name: "admin", role: :admin})
  Enum.each([avenger, mentor] ++ students, &insert(:nusnet_id, %{user: &1}))

  # Assessments
  for _ <- 1..5 do
    assessment = insert(:assessment, %{is_published: true})

    programming_questions =
      insert_list(3, :question, %{
        type: :programming,
        library: if(Enum.random(0..2) == 0, do: build(:library)),
        question: build(:programming_question),
        assessment: assessment,
        max_xp: 200
      })

    mcq_questions =
      insert_list(3, :question, %{
        type: :multiple_choice,
        question: build(:mcq_question),
        assessment: assessment,
        max_xp: 40
      })

    submissions =
      students
      |> Enum.take(2)
      |> Enum.map(&insert(:submission, %{assessment: assessment, student: &1}))

    # Programming Answers
    for submission <- submissions,
        question <- programming_questions do
      insert(:answer, %{
        xp: 200,
        question: question,
        submission: submission,
        answer: build(:programming_answer)
      })
    end

    # MCQ Answers    for submission <- submissions,
    question <-
      mcq_questions do
        insert(:answer, %{
          xp: 200,
          question: question,
          submission: submission,
          answer: build(:mcq_answer)
        })
      end
  end
end
