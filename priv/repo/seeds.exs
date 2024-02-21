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
use Cadet, [:context, :display]

import Cadet.Factory
import Cadet.Factory
import Ecto.Query

alias Cadet.Assessments.SubmissionStatus

alias Cadet.Accounts.{
  User,
  CourseRegistration
}

# insert default source version
# Cadet.Repo.insert!(%Cadet.Settings.Sublanguage{chapter: 1, variant: "default"})

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

  admin_cr =
    if admin_cr == nil do
      admin =
        insert(:user, %{name: "Test Admin", username: "admin", latest_viewed_course: course})

      insert(:course_registration, %{user: admin, course: course, role: :admin})
    else
      admin_cr
    end

  group = insert(:group, %{name: "MockGroup", leader: admin_cr})

  # Users

  students =
    for i <- 1..number_of_students do
      student = insert(:user, %{latest_viewed_course: course})

      student_cr =
        insert(:course_registration, %{
          user: student,
          course: course,
          role: :student,
          group: group
        })

      student_cr
    end

  # Assessments and Submissions
  valid_assessment_types = [{1, "Missions"}, {2, "Paths"}, {3, "Quests"}]

  assessment_configs =
    Enum.map(valid_assessment_types, fn {order, type} ->
      insert(:assessment_config, %{type: type, order: order, course: course})
    end)

  for i <- 1..number_of_assessments do
    assessment =
      insert(:assessment, %{
        is_published: true,
        config: Enum.random(assessment_configs),
        course: course
      })

    questions =
      case assessment.config.type do
        "Missions" ->
          insert_list(3, :programming_question, %{assessment: assessment, max_xp: 1_000})

        "Paths" ->
          insert_list(3, :mcq_question, %{assessment: assessment, max_xp: 500})

        "Quests" ->
          insert_list(3, :programming_question, %{assessment: assessment, max_xp: 1_000})
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

    # # Notifications
    # for submission <- submissions do
    #   case submission.status do
    #     :submitted ->
    #       insert(:notification, %{
    #         type: :submitted,
    #         read: false,
    #         user_id: avenger.id,
    #         submission_id: submission.id,
    #         assessment_id: assessment.id
    #       })

    #     _ ->
    #       nil
    #   end
    # end

    # for student <- students do
    #   insert(:notification, %{
    #     type: :new,
    #     user_id: student.id,
    #     assessment_id: assessment.id
    #   })
    # end
  end

  # goal_0 =
  #   insert(:goal, %{
  #     text: "Complete Beyond the Second Dimension achievement",
  #     max_xp: 250
  #   })

  # goal_1 =
  #   insert(:goal, %{
  #     text: "Complete Colorful Carpet achievement",
  #     max_xp: 250
  #   })

  # goal_2 =
  #   insert(:goal, %{
  #     text: "Bonus for completing Rune Master achievement",
  #     max_xp: 250
  #   })

  # goal_3 =
  #   insert(:goal, %{
  #     text: "Complete Beyond the Second Dimension mission",
  #     max_xp: 100
  #   })

  # goal_4 =
  #   insert(:goal, %{
  #     text: "Score earned from Beyond the Second Dimension mission",
  #     max_xp: 150
  #   })

  # goal_5 =
  #   insert(:goal, %{
  #     text: "Complete Colorful Carpet mission",
  #     max_xp: 100
  #   })

  # goal_6 =
  #   insert(:goal, %{
  #     text: "Score earned from Colorful Carpet mission",
  #     max_xp: 150
  #   })

  # goal_7 =
  #   insert(:goal, %{
  #     text: "Complete Curve Introduction mission",
  #     max_xp: 250
  #   })

  # goal_8 =
  #   insert(:goal, %{
  #     text: "Complete Curve Manipulation mission",
  #     max_xp: 250
  #   })

  # goal_9 =
  #   insert(:goal, %{
  #     text: "Bonus for completing Curve Wizard achievement",
  #     max_xp: 100
  #   })

  # goal_10 =
  #   insert(:goal, %{
  #     text: "Complete Curve Introduction mission",
  #     max_xp: 50
  #   })

  # goal_11 =
  #   insert(:goal, %{
  #     text: "Score earned from Curve Introduction mission",
  #     max_xp: 200
  #   })

  # goal_12 =
  #   insert(:goal, %{
  #     text: "Complete Curve Manipulation mission",
  #     max_xp: 50
  #   })

  # goal_13 =
  #   insert(:goal, %{
  #     text: "Score earned from Curve Manipulation mission",
  #     max_xp: 200
  #   })

  # goal_14 =
  #   insert(:goal, %{
  #     text: "Complete Source 3 path",
  #     max_xp: 100
  #   })

  # goal_15 =
  #   insert(:goal, %{
  #     text: "Score earned from Source 3 path",
  #     max_xp: 300
  #   })

  # goal_16 =
  #   insert(:goal, %{
  #     text: "Complete Piazza Guru achievement",
  #     max_xp: 100
  #   })

  # goal_17 =
  #   insert(:goal, %{
  #     text: "Each Top Voted answer in Piazza gives 10 XP",
  #     max_xp: 100
  #   })

  # goal_18 =
  #   insert(:goal, %{
  #     text: "Submit 1 PR to Source Academy Github",
  #     max_xp: 100
  #   })

  # # Achievements
  # achievement_0 =
  #   insert(:achievement, %{
  #     title: "Rune Master",
  #     is_task: true,
  #     position: 1,
  #     card_tile_url:
  #       "https://source-academy-assets.s3-ap-southeast-1.amazonaws.com/achievement/card-tile/rune-master-tile.png",
  #     goals: [
  #       %{goal_uuid: goal_0.uuid},
  #       %{goal_uuid: goal_1.uuid},
  #       %{goal_uuid: goal_2.uuid}
  #     ]
  #   })

  # achievement_1 =
  #   insert(:achievement, %{
  #     title: "Beyond the Second Dimension",
  #     is_task: false,
  #     position: 0,
  #     card_tile_url:
  #       "https://source-academy-assets.s3-ap-southeast-1.amazonaws.com/achievement/card-tile/btsd-tile.png",
  #     open_at: ~U[2020-07-16 16:00:00Z],
  #     close_at: ~U[2020-07-20 16:00:00Z],
  #     goals: [
  #       %{goal_uuid: goal_3.uuid},
  #       %{goal_uuid: goal_4.uuid}
  #     ]
  #   })

  # achievement_2 =
  #   insert(:achievement, %{
  #     title: "Colorful Carpet",
  #     is_task: false,
  #     position: 0,
  #     card_tile_url:
  #       "https://source-academy-assets.s3-ap-southeast-1.amazonaws.com/achievement/card-tile/colorful-carpet-tile.png",
  #     open_at: ~U[2020-07-11 16:00:00Z],
  #     close_at: ~U[2020-07-15 16:00:00Z],
  #     goals: [
  #       %{goal_uuid: goal_5.uuid},
  #       %{goal_uuid: goal_6.uuid}
  #     ]
  #   })

  # achievement_3 =
  #   insert(:achievement, %{
  #     title: "Unpublished",
  #     is_task: false,
  #     position: 0,
  #     card_tile_url:
  #       "https://www.publicdomainpictures.net/pictures/30000/velka/plain-white-background.jpg"
  #   })

  # achievement_4 =
  #   insert(:achievement, %{
  #     title: "Curve Wizard",
  #     is_task: true,
  #     position: 4,
  #     card_tile_url:
  #       "https://source-academy-assets.s3-ap-southeast-1.amazonaws.com/achievement/card-tile/curve-wizard-tile.png",
  #     open_at: ~U[2020-07-31 16:00:00Z],
  #     close_at: ~U[2020-08-04 16:00:00Z],
  #     goals: [
  #       %{goal_uuid: goal_7.uuid},
  #       %{goal_uuid: goal_8.uuid},
  #       %{goal_uuid: goal_9.uuid}
  #     ]
  #   })

  # achievement_5 =
  #   insert(:achievement, %{
  #     title: "Curve Introduction",
  #     is_task: false,
  #     position: 0,
  #     card_tile_url:
  #       "https://source-academy-assets.s3-ap-southeast-1.amazonaws.com/achievement/card-tile/curve-introduction-tile.png",
  #     open_at: ~U[2020-07-23 16:00:00Z],
  #     close_at: ~U[2020-07-27 16:00:00Z],
  #     goals: [
  #       %{goal_uuid: goal_10.uuid},
  #       %{goal_uuid: goal_11.uuid}
  #     ]
  #   })

  # achievement_6 =
  #   insert(:achievement, %{
  #     title: "Curve Manipulation",
  #     is_task: false,
  #     position: 0,
  #     card_tile_url:
  #       "https://source-academy-assets.s3-ap-southeast-1.amazonaws.com/achievement/card-tile/curve-manipulation-tile.png",
  #     open_at: ~U[2020-07-31 16:00:00Z],
  #     close_at: ~U[2020-08-04 16:00:00Z],
  #     goals: [
  #       %{goal_uuid: goal_12.uuid},
  #       %{goal_uuid: goal_13.uuid}
  #     ]
  #   })

  # achievement_7 =
  #   insert(:achievement, %{
  #     title: "The Source-rer",
  #     is_task: true,
  #     position: 3,
  #     card_tile_url:
  #       "https://source-academy-assets.s3-ap-southeast-1.amazonaws.com/achievement/card-tile/the-source-rer-tile.png",
  #     open_at: ~U[2020-07-16 16:00:00Z],
  #     close_at: ~U[2020-07-20 16:00:00Z],
  #     goals: [
  #       %{goal_uuid: goal_14.uuid},
  #       %{goal_uuid: goal_15.uuid}
  #     ]
  #   })

  # achievement_8 =
  #   insert(:achievement, %{
  #     title: "Power of Friendship",
  #     is_task: true,
  #     position: 2,
  #     card_tile_url:
  #       "https://source-academy-assets.s3-ap-southeast-1.amazonaws.com/achievement/card-tile/power-of-friendship-tile.png",
  #     open_at: ~U[2020-07-16 16:00:00Z],
  #     close_at: ~U[2020-07-20 16:00:00Z],
  #     goals: [
  #       %{goal_uuid: goal_16.uuid}
  #     ]
  #   })

  # achievement_9 =
  #   insert(:achievement, %{
  #     title: "Piazza Guru",
  #     is_task: false,
  #     position: 0,
  #     card_tile_url:
  #       "https://source-academy-assets.s3-ap-southeast-1.amazonaws.com/achievement/card-tile/piazza-guru-tile.png",
  #     goals: [
  #       %{goal_uuid: goal_17.uuid}
  #     ]
  #   })

  # achievement_10 =
  #   insert(:achievement, %{
  #     title: "Thats the Spirit",
  #     is_task: true,
  #     position: 5,
  #     card_tile_url:
  #       "https://source-academy-assets.s3-ap-southeast-1.amazonaws.com/achievement/card-tile/annotated-tile.png",
  #     goals: [
  #       %{goal_uuid: goal_18.uuid}
  #     ]
  #   })

  # insert(:achievement_prerequisite, %{
  #   prerequisite_uuid: achievement_9.uuid,
  #   achievement_uuid: achievement_8.uuid
  # })

  # insert(:achievement_prerequisite, %{
  #   prerequisite_uuid: achievement_5.uuid,
  #   achievement_uuid: achievement_4.uuid
  # })

  # insert(:achievement_prerequisite, %{
  #   prerequisite_uuid: achievement_6.uuid,
  #   achievement_uuid: achievement_4.uuid
  # })

  # insert(:achievement_prerequisite, %{
  #   prerequisite_uuid: achievement_1.uuid,
  #   achievement_uuid: achievement_0.uuid
  # })

  # insert(:achievement_prerequisite, %{
  #   prerequisite_uuid: achievement_2.uuid,
  #   achievement_uuid: achievement_0.uuid
  # })
end
