defmodule Cadet.Accounts.TeamTest do
  use Cadet.DataCase
  alias Cadet.Accounts.{Teams, TeamMember, CourseRegistrations}
  alias Cadet.Assessments.{Submission, Answer}
  alias Cadet.Repo

  setup do
    user1 = insert(:user, %{name: "user 1"})
    user2 = insert(:user, %{name: "user 2"})
    user3 = insert(:user, %{name: "user 3"})
    course1 = insert(:course, %{course_short_name: "course 1"})
    course2 = insert(:course, %{course_short_name: "course 2"})
    assessment1 = insert(:assessment, %{title: "A1", max_team_size: 3, course: course1})
    assessment2 = insert(:assessment, %{title: "A2", max_team_size: 2, course: course1})

    {:ok,
     %{
       user1: user1,
       user2: user2,
       user3: user3,
       course1: course1,
       course2: course2,
       assessment1: assessment1,
       assessment2: assessment2
     }}
  end

  test "creating a new team with valid attributes", %{
    user1: user1,
    user2: user2,
    assessment1: assessment1,
    course1: course1
  } do
    {:ok, course_reg1} =
      CourseRegistrations.insert_or_update_course_registration(%{
        user_id: user1.id,
        course_id: course1.id,
        role: :student
      })

    {:ok, course_reg2} =
      CourseRegistrations.insert_or_update_course_registration(%{
        user_id: user2.id,
        course_id: course1.id,
        role: :student
      })

    attrs = %{
      "assessment_id" => assessment1.id,
      "student_ids" => [
        [%{"userId" => course_reg1.id}, %{"userId" => course_reg2.id}]
      ]
    }

    assert {:ok, team} = Teams.create_team(attrs)

    team_members =
      TeamMember
      |> where([tm], tm.team_id == ^team.id)
      |> Repo.all()

    assert length(team_members) == 2
  end

  test "creating a new team with duplicate students in the one row", %{
    user1: user1,
    assessment1: assessment1,
    course1: course1
  } do
    {:ok, course_reg1} =
      CourseRegistrations.insert_or_update_course_registration(%{
        user_id: user1.id,
        course_id: course1.id,
        role: :student
      })

    attrs = %{
      "assessment_id" => assessment1.id,
      "student_ids" => [
        [%{"userId" => course_reg1.id}, %{"userId" => course_reg1.id}]
      ]
    }

    result = Teams.create_team(attrs)

    assert result ==
             {:error, {:conflict, "One or more students appear multiple times in a team!"}}
  end

  test "creating a new team with duplicate students across the teams but not in one row", %{
    user1: user1,
    user2: user2,
    user3: user3,
    assessment1: assessment1,
    course1: course1
  } do
    {:ok, course_reg1} =
      CourseRegistrations.insert_or_update_course_registration(%{
        user_id: user1.id,
        course_id: course1.id,
        role: :student
      })

    {:ok, course_reg2} =
      CourseRegistrations.insert_or_update_course_registration(%{
        user_id: user2.id,
        course_id: course1.id,
        role: :student
      })

    {:ok, course_reg3} =
      CourseRegistrations.insert_or_update_course_registration(%{
        user_id: user3.id,
        course_id: course1.id,
        role: :student
      })

    attrs = %{
      "assessment_id" => assessment1.id,
      "student_ids" => [
        [%{"userId" => course_reg1.id}, %{"userId" => course_reg2.id}],
        [%{"userId" => course_reg2.id}, %{"userId" => course_reg3.id}]
      ]
    }

    result = Teams.create_team(attrs)

    assert result ==
             {:error, {:conflict, "One or more students appear multiple times in a team!"}}
  end

  test "creating a team with students already in another team for the same assessment", %{
    user1: user1,
    user2: user2,
    user3: user3,
    assessment1: assessment1,
    course1: course1
  } do
    {:ok, course_reg1} =
      CourseRegistrations.insert_or_update_course_registration(%{
        user_id: user1.id,
        course_id: course1.id,
        role: :student
      })

    {:ok, course_reg2} =
      CourseRegistrations.insert_or_update_course_registration(%{
        user_id: user2.id,
        course_id: course1.id,
        role: :student
      })

    {:ok, course_reg3} =
      CourseRegistrations.insert_or_update_course_registration(%{
        user_id: user3.id,
        course_id: course1.id,
        role: :student
      })

    attrs_valid = %{
      "assessment_id" => assessment1.id,
      "student_ids" => [
        [%{"userId" => course_reg1.id}, %{"userId" => course_reg2.id}]
      ]
    }

    assert {:ok, _team} = Teams.create_team(attrs_valid)

    attrs_invalid = %{
      "assessment_id" => assessment1.id,
      "student_ids" => [
        [%{"userId" => course_reg1.id}, %{"userId" => course_reg3.id}]
      ]
    }

    result = Teams.create_team(attrs_invalid)

    assert result ==
             {:error, {:conflict, "One or more students already in a team for this assessment!"}}
  end

  test "creating a team with students exceeding the maximum team size", %{
    user1: user1,
    user2: user2,
    user3: user3,
    assessment2: assessment2,
    course1: course1
  } do
    {:ok, course_reg1} =
      CourseRegistrations.insert_or_update_course_registration(%{
        user_id: user1.id,
        course_id: course1.id,
        role: :student
      })

    {:ok, course_reg2} =
      CourseRegistrations.insert_or_update_course_registration(%{
        user_id: user2.id,
        course_id: course1.id,
        role: :student
      })

    {:ok, course_reg3} =
      CourseRegistrations.insert_or_update_course_registration(%{
        user_id: user3.id,
        course_id: course1.id,
        role: :student
      })

    attrs_invalid = %{
      "assessment_id" => assessment2.id,
      "student_ids" => [
        [
          %{"userId" => course_reg1.id},
          %{"userId" => course_reg2.id},
          %{"userId" => course_reg3.id}
        ]
      ]
    }

    result = Teams.create_team(attrs_invalid)
    assert result == {:error, {:conflict, "One or more teams exceed the maximum team size!"}}
  end

  test "inserting a team with non-exisiting student", %{
    user1: user1,
    user2: user2,
    assessment1: assessment1,
    course1: course1
  } do
    {:ok, course_reg1} =
      CourseRegistrations.insert_or_update_course_registration(%{
        user_id: user1.id,
        course_id: course1.id,
        role: :student
      })

    {:ok, course_reg2} =
      CourseRegistrations.insert_or_update_course_registration(%{
        user_id: user2.id,
        course_id: course1.id,
        role: :student
      })

    attrs_invalid = %{
      "assessment_id" => assessment1.id,
      "student_ids" => [
        [%{"userId" => course_reg1.id}, %{"userId" => course_reg2.id}, %{"userId" => 99_999}]
      ]
    }

    result = Teams.create_team(attrs_invalid)
    assert result == {:error, {:conflict, "One or more students not enrolled in this course!"}}
  end

  test "inserting a team with an exisiting student but not enrolled in this course", %{
    user1: user1,
    user2: user2,
    assessment1: assessment1,
    course1: course1,
    course2: course2
  } do
    {:ok, course_reg1} =
      CourseRegistrations.insert_or_update_course_registration(%{
        user_id: user1.id,
        course_id: course1.id,
        role: :student
      })

    {:ok, course_reg2} =
      CourseRegistrations.insert_or_update_course_registration(%{
        user_id: user2.id,
        course_id: course2.id,
        role: :student
      })

    attrs_invalid = %{
      "assessment_id" => assessment1.id,
      "student_ids" => [
        [%{"userId" => course_reg1.id}, %{"userId" => course_reg2.id}]
      ]
    }

    result = Teams.create_team(attrs_invalid)
    assert result == {:error, {:conflict, "One or more students not enrolled in this course!"}}
  end

  test "update an existing team with valid new team members", %{
    user1: user1,
    user2: user2,
    user3: user3,
    assessment1: assessment1,
    course1: course1
  } do
    {:ok, course_reg1} =
      CourseRegistrations.insert_or_update_course_registration(%{
        user_id: user1.id,
        course_id: course1.id,
        role: :student
      })

    {:ok, course_reg2} =
      CourseRegistrations.insert_or_update_course_registration(%{
        user_id: user2.id,
        course_id: course1.id,
        role: :student
      })

    {:ok, course_reg3} =
      CourseRegistrations.insert_or_update_course_registration(%{
        user_id: user3.id,
        course_id: course1.id,
        role: :student
      })

    attrs = %{
      "assessment_id" => assessment1.id,
      "student_ids" => [
        [%{"userId" => course_reg1.id}, %{"userId" => course_reg2.id}]
      ]
    }

    new_ids = [
      [
        %{"userId" => course_reg1.id},
        %{"userId" => course_reg2.id},
        %{"userId" => course_reg3.id}
      ]
    ]

    assert {:ok, team} = Teams.create_team(attrs)
    team = Repo.preload(team, :team_members)
    assert {:ok, team} = Teams.update_team(team, team.assessment_id, new_ids)

    team_members =
      TeamMember
      |> where([tm], tm.team_id == ^team.id)
      |> Repo.all()

    assert length(team_members) == 3
  end

  test "update an existing team with new team members who are already in another team", %{
    user1: user1,
    user2: user2,
    user3: user3,
    assessment1: assessment1,
    course1: course1
  } do
    {:ok, course_reg1} =
      CourseRegistrations.insert_or_update_course_registration(%{
        user_id: user1.id,
        course_id: course1.id,
        role: :student
      })

    {:ok, course_reg2} =
      CourseRegistrations.insert_or_update_course_registration(%{
        user_id: user2.id,
        course_id: course1.id,
        role: :student
      })

    {:ok, course_reg3} =
      CourseRegistrations.insert_or_update_course_registration(%{
        user_id: user3.id,
        course_id: course1.id,
        role: :student
      })

    attrs1 = %{
      "assessment_id" => assessment1.id,
      "student_ids" => [
        [%{"userId" => course_reg1.id}, %{"userId" => course_reg2.id}]
      ]
    }

    attrs2 = %{
      "assessment_id" => assessment1.id,
      "student_ids" => [
        [%{"userId" => course_reg3.id}]
      ]
    }

    new_ids = [
      [
        %{"userId" => course_reg1.id},
        %{"userId" => course_reg2.id},
        %{"userId" => course_reg3.id}
      ]
    ]

    assert {:ok, team1} = Teams.create_team(attrs1)
    assert {:ok, _team2} = Teams.create_team(attrs2)
    team1 = Repo.preload(team1, :team_members)

    result = Teams.update_team(team1, team1.assessment_id, new_ids)

    assert result ==
             {:error,
              {:conflict,
               "One or more students are already in another team for the same assessment!"}}
  end

  test "delete an existing team", %{
    user1: user1,
    user2: user2,
    user3: user3,
    assessment1: assessment1,
    course1: course1
  } do
    {:ok, course_reg1} =
      CourseRegistrations.insert_or_update_course_registration(%{
        user_id: user1.id,
        course_id: course1.id,
        role: :student
      })

    {:ok, course_reg2} =
      CourseRegistrations.insert_or_update_course_registration(%{
        user_id: user2.id,
        course_id: course1.id,
        role: :student
      })

    {:ok, course_reg3} =
      CourseRegistrations.insert_or_update_course_registration(%{
        user_id: user3.id,
        course_id: course1.id,
        role: :student
      })

    attrs = %{
      "assessment_id" => assessment1.id,
      "student_ids" => [
        [
          %{"userId" => course_reg1.id},
          %{"userId" => course_reg2.id},
          %{"userId" => course_reg3.id}
        ]
      ]
    }

    assert {:ok, team} = Teams.create_team(attrs)

    submission =
      insert(:submission, %{
        team: team,
        student: nil,
        assessment: assessment1
      })

    submission_id = submission.id

    _answer = %Answer{
      submission_id: submission_id
    }

    assert {:ok, deleted_team} = Teams.delete_team(team)
    assert deleted_team.id == team.id

    team_members =
      TeamMember
      |> where([tm], tm.team_id == ^team.id)
      |> Repo.all()

    assert team_members == []

    submissions =
      Submission
      |> where([s], s.team_id == ^team.id)
      |> Repo.all()

    assert submissions == []

    answers =
      Answer
      |> where(submission_id: ^submission_id)
      |> Repo.all()

    assert answers == []
  end

  test "delete an existing team with submission", %{
    user1: user1,
    user2: user2,
    user3: user3,
    assessment1: assessment1,
    course1: course1
  } do
    {:ok, course_reg1} =
      CourseRegistrations.insert_or_update_course_registration(%{
        user_id: user1.id,
        course_id: course1.id,
        role: :student
      })

    {:ok, course_reg2} =
      CourseRegistrations.insert_or_update_course_registration(%{
        user_id: user2.id,
        course_id: course1.id,
        role: :student
      })

    {:ok, course_reg3} =
      CourseRegistrations.insert_or_update_course_registration(%{
        user_id: user3.id,
        course_id: course1.id,
        role: :student
      })

    attrs = %{
      "assessment_id" => assessment1.id,
      "student_ids" => [
        [
          %{"userId" => course_reg1.id},
          %{"userId" => course_reg2.id},
          %{"userId" => course_reg3.id}
        ]
      ]
    }

    assert {:ok, team} = Teams.create_team(attrs)

    submission = %Submission{
      team_id: team.id,
      assessment_id: assessment1.id,
      status: :submitted
    }

    {:ok, _inserted_submission} = Repo.insert(submission)

    result = Teams.delete_team(team)

    assert result ==
             {:error,
              {:conflict, "This team has submitted their answers! Unable to delete the team!"}}
  end
end
