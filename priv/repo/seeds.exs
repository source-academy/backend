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
  mission = insert(:assessment, %{title: "mission", type: :mission, is_published: true})

  questions =
    insert_list(3, :question, %{
      type: :programming,
      question: build(:programming_question),
      assessment: mission,
      max_xp: 200
    })

  submissions =
    students
    |> Enum.take(2)
    |> Enum.map(&insert(:submission, %{assessment: mission, student: &1}))

  # Answers
  Enum.each(submissions, fn submission ->
    Enum.each(questions, fn question ->
      insert(:answer, %{
        xp: 200,
        question: question,
        submission: submission,
        answer: build(:programming_answer)
      })
    end)
  end)
end
