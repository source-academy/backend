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

  # Achievements
  achievement_0 =
    insert(:achievement, %{
      id: 0,
      title: "Rune Master",
      ability: "Core",
      is_task: true,
      position: 1,
      card_tile_url:
        "https://source-academy-assets.s3-ap-southeast-1.amazonaws.com/achievement/card-tile/rune-master-tile.png",
      goals: [
        %{
          order: 0,
          text: "Complete Beyond the Second Dimension achievement",
          target: 250
        },
        %{
          order: 1,
          text: "Complete Colorful Carpet achievement",
          target: 250
        },
        %{
          order: 2,
          text: "Bonus for completing Rune Master achievement",
          target: 250
        }
      ]
    })

  achievement_1 =
    insert(:achievement, %{
      id: 1,
      title: "Beyond the Second Dimension",
      ability: "Core",
      is_task: false,
      position: 0,
      card_tile_url:
        "https://source-academy-assets.s3-ap-southeast-1.amazonaws.com/achievement/card-tile/btsd-tile.png",
      open_at: ~U[2020-07-16 16:00:00Z],
      close_at: ~U[2020-07-20 16:00:00Z],
      goals: [
        %{
          order: 0,
          text: "Complete Beyond the Second Dimension mission",
          target: 100
        },
        %{
          order: 1,
          text: "Score earned from Beyond the Second Dimension mission",
          target: 150
        }
      ]
    })

  achievement_2 =
    insert(:achievement, %{
      id: 2,
      title: "Colorful Carpet",
      ability: "Core",
      is_task: false,
      position: 0,
      card_tile_url:
        "https://source-academy-assets.s3-ap-southeast-1.amazonaws.com/achievement/card-tile/colorful-carpet-tile.png",
      open_at: ~U[2020-07-11 16:00:00Z],
      close_at: ~U[2020-07-15 16:00:00Z],
      goals: [
        %{
          order: 0,
          text: "Complete Colorful Carpet mission",
          target: 100
        },
        %{
          order: 1,
          text: "Score earned from Colorful Carpet mission",
          target: 150
        }
      ]
    })

  achievement_3 =
    insert(:achievement, %{
      id: 3,
      title: "Unpublished",
      ability: "Core",
      is_task: false,
      position: 0,
      card_tile_url:
        "https://www.publicdomainpictures.net/pictures/30000/velka/plain-white-background.jpg"
    })

  achievement_4 =
    insert(:achievement, %{
      id: 4,
      title: "Curve Wizard",
      ability: "Core",
      is_task: true,
      position: 4,
      card_tile_url:
        "https://source-academy-assets.s3-ap-southeast-1.amazonaws.com/achievement/card-tile/curve-wizard-tile.png",
      open_at: ~U[2020-07-31 16:00:00Z],
      close_at: ~U[2020-08-04 16:00:00Z],
      goals: [
        %{
          order: 0,
          text: "Complete Curve Introduction mission",
          target: 250
        },
        %{
          order: 1,
          text: "Complete Curve Manipulation mission",
          target: 250
        },
        %{
          order: 2,
          text: "Bonus for completing Curve Wizard achievement",
          target: 100
        }
      ]
    })

  achievement_5 =
    insert(:achievement, %{
      id: 5,
      title: "Curve Introduction",
      ability: "Core",
      is_task: false,
      position: 0,
      card_tile_url:
        "https://source-academy-assets.s3-ap-southeast-1.amazonaws.com/achievement/card-tile/curve-introduction-tile.png",
      open_at: ~U[2020-07-23 16:00:00Z],
      close_at: ~U[2020-07-27 16:00:00Z],
      goals: [
        %{
          order: 0,
          text: "Complete Curve Introduction mission",
          target: 50
        },
        %{
          order: 1,
          text: "Score earned from Curve Introduction mission",
          target: 200
        }
      ]
    })

  achievement_6 =
    insert(:achievement, %{
      id: 6,
      title: "Curve Manipulation",
      ability: "Core",
      is_task: false,
      position: 0,
      card_tile_url:
        "https://source-academy-assets.s3-ap-southeast-1.amazonaws.com/achievement/card-tile/curve-manipulation-tile.png",
      open_at: ~U[2020-07-31 16:00:00Z],
      close_at: ~U[2020-08-04 16:00:00Z],
      goals: [
        %{
          order: 0,
          text: "Complete Curve Manipulation mission",
          target: 50
        },
        %{
          order: 1,
          text: "Score earned from Curve Manipulation mission",
          target: 200
        }
      ]
    })

  achievement_7 =
    insert(:achievement, %{
      id: 7,
      title: "The Source-rer",
      ability: "Effort",
      is_task: true,
      position: 3,
      card_tile_url:
        "https://source-academy-assets.s3-ap-southeast-1.amazonaws.com/achievement/card-tile/the-source-rer-tile.png",
      open_at: ~U[2020-07-16 16:00:00Z],
      close_at: ~U[2020-07-20 16:00:00Z],
      goals: [
        %{
          order: 0,
          text: "Complete Source 3 path",
          target: 100
        },
        %{
          order: 1,
          text: "Score earned from Source 3 path",
          target: 300
        }
      ]
    })

  achievement_8 =
    insert(:achievement, %{
      id: 8,
      title: "Power of Friendship",
      ability: "Community",
      is_task: true,
      position: 2,
      card_tile_url:
        "https://source-academy-assets.s3-ap-southeast-1.amazonaws.com/achievement/card-tile/power-of-friendship-tile.png",
      open_at: ~U[2020-07-16 16:00:00Z],
      close_at: ~U[2020-07-20 16:00:00Z],
      goals: [
        %{
          order: 0,
          text: "Complete Piazza Guru achievement",
          target: 100
        }
      ]
    })

  achievement_9 =
    insert(:achievement, %{
      id: 9,
      title: "Piazza Guru",
      ability: "Community",
      is_task: false,
      position: 0,
      card_tile_url:
        "https://source-academy-assets.s3-ap-southeast-1.amazonaws.com/achievement/card-tile/piazza-guru-tile.png",
      goals: [
        %{
          order: 0,
          text: "Each Top Voted answer in Piazza gives 10 XP",
          target: 100
        }
      ]
    })

  achievement_10 =
    insert(:achievement, %{
      id: 10,
      title: "Thats the Spirit",
      ability: "Exploration",
      is_task: true,
      position: 5,
      card_tile_url:
        "https://source-academy-assets.s3-ap-southeast-1.amazonaws.com/achievement/card-tile/annotated-tile.png",
      goals: [
        %{
          order: 0,
          text: "Submit 1 PR to Source Academy Github",
          target: 100
        }
      ]
    })

  insert(:achievement_prerequisite, %{
    prerequisite_id: achievement_9.id,
    achievement_id: achievement_8.id
  })

  insert(:achievement_prerequisite, %{
    prerequisite_id: achievement_5.id,
    achievement_id: achievement_4.id
  })

  insert(:achievement_prerequisite, %{
    prerequisite_id: achievement_6.id,
    achievement_id: achievement_4.id
  })

  insert(:achievement_prerequisite, %{
    prerequisite_id: achievement_1.id,
    achievement_id: achievement_0.id
  })

  insert(:achievement_prerequisite, %{
    prerequisite_id: achievement_2.id,
    achievement_id: achievement_0.id
  })
end
