# Script for populating the database. You can run it as:
# TODO Change the following line to the correct path
#     mix run priv/repo/seeds_wip.exs
#
use Cadet, [:context, :display]
import Cadet.Factory
import Ecto.Query
alias Cadet.Assessments.SubmissionStatus
alias Cadet.Accounts.{
  User,
  CourseRegistration,
}

if Cadet.Env.env() == :dev do
  number_of_assessments = 10
  number_of_students = 100

  # Course
  course = insert(:course, %{course_name: "Mock Course", course_short_name: "CS0000S"})

  # Admin and Group
  admin_cr =
    from(cr in CourseRegistration,
      where: cr.user_id in subquery(from(u in User, where: u.name == ^"admin", select: u.id)),
      select: cr
    )
    |> Repo.one()
  if admin_cr == nil do
    admin = insert(:user, %{name: "Test Admin", username: "admin", latest_viewed_course: course})
    _admin_cr = insert(:course_registration, %{user: admin, course: course, role: :admin})
  end

  group = insert(:group, %{name: "MockGroup", leader: admin_cr})

  # Users

  students = for i <- 1..number_of_students do
    student = insert(:user, %{latest_viewed_course: course})

    student_cr =
      insert(:course_registration, %{user: student, course: course, role: :student, group: group})

    student_cr
  end

  # Assessments and Submissions
  valid_assessment_types = [{1, "Mission"}, {2, "Path"}, {3, "Quest"}]
  assessment_configs = Enum.map(valid_assessment_types, fn {order, type} ->
    insert(:assessment_config, %{type: type, order: order, course: course})
  end
  )

  for i <- 1..number_of_assessments do

    assessment = insert(:assessment, %{is_published: true, config: Enum.random(assessment_configs), course: course})

    questions = case assessment.config.type do
      "Mission" ->
          insert_list(3, :programming_question, %{assessment: assessment, max_xp: 1_000})

      "Path" ->
          insert_list(3, :mcq_question, %{assessment: assessment, max_xp: 500})

      "Quest" ->
          insert_list(3, :programming_question, %{assessment: assessment, max_xp: 500})
      end

        submissions =
          students
          |> Enum.map(
            &insert(:submission, %{
              assessment: assessment,
              student: &1,
              status: Enum.random(SubmissionStatus.__enum_map__())
            })
          )

        for submission <- submissions,
            question <- questions do
          case question.type do
            :programming ->
              insert(:answer, %{
                xp: Enum.random(0..1_000),
                question: question,
                submission: submission,
                answer: build(:programming_answer)
              })

            :mcq ->
              insert(:answer, %{
                xp: Enum.random(0..500),
                question: question,
                submission: submission,
                answer: build(:mcq_answer)
              })
          end
        end
    end
  end
