defmodule Cadet.Accounts.TeamTest do
    use Cadet.DataCase
    alias Cadet.Accounts.{Teams, Team, TeamMember, User, CourseRegistration, CourseRegistrations}
    alias Cadet.Assessments.{Assessment}
    alias Cadet.Repo

    setup do
        user1 = insert(:user, %{name: "user 1"})
        user2 = insert(:user, %{name: "user 2"})
        user3 = insert(:user, %{name: "user 3"})

        assessment1 = insert(:assessment, %{title: "A1", max_team_size: 3})    
        course1 = insert(:course, %{course_short_name: "course 1"})

        {:ok, %{
            user1: user1,
            user2: user2,
            user3: user3,
            course1: course1,
            assessment1: assessment1
        }}
    end

    test "creating a new team with valid attributes", %{user1: user1, user2: user2, assessment1: assessment1, course1: course1} do
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
                [%{"userId" => course_reg1.id},%{"userId" => course_reg2.id}],
            ]
        }

        assert {:ok, team} = Teams.create_team(attrs)

        # Check the number of team members
        team_members = TeamMember
            |> where([tm], tm.team_id == ^team.id) # Filtering by team ID
            |> Repo.all()

        assert length(team_members) == 2

    end

    test "creating a new team with duplicate students in the list", %{user1: user1, assessment1: assessment1, course1: course1} do
        {:ok, course_reg1} =
            CourseRegistrations.insert_or_update_course_registration(%{
                user_id: user1.id,
                course_id: course1.id,
                role: :student
            })

        attrs = %{
            "assessment_id" => assessment1.id,
            "student_ids" => [
                [%{"userId" => course_reg1.id},%{"userId" => course_reg1.id}],
            ]
        }

        result = Teams.create_team(attrs) 
        assert result == {:halt, {:error, {:conflict, "One or more students appears multiple times in a team!"}}}
    end

    test "creating a team with students already in another team for the same assessment", %{user1: user1, user2: user2, user3: user3, assessment1: assessment1, course1: course1}  do

        {:ok, course_reg1} = CourseRegistrations.insert_or_update_course_registration(%{user_id: user1.id, course_id: course1.id, role: :student})
        {:ok, course_reg2} = CourseRegistrations.insert_or_update_course_registration(%{user_id: user2.id, course_id: course1.id, role: :student})
        {:ok, course_reg3} = CourseRegistrations.insert_or_update_course_registration(%{user_id: user3.id, course_id: course1.id, role: :student})
        
        attrs_valid = %{
        "assessment_id" => assessment1.id,
        "student_ids" => [
            [%{"userId" => course_reg1.id},%{"userId" => course_reg2.id}],
        ]
        }

        assert {:ok, team} = Teams.create_team(attrs_valid)

        attrs_invalid = %{
        "assessment_id" => assessment1.id,
        "student_ids" => [
            [%{"userId" => course_reg1.id},%{"userId" => course_reg3.id}],
        ]
        }

        result = Teams.create_team(attrs_invalid)
        assert result == {:halt, {:error, {:conflict, "One or more students already in a team for this assessment!"}}}

    end

#   test "updating an existing team with valid attributes" do
#     # Test case for updating an existing team
#     # Set up the initial conditions
#     # ...

#     # Perform the assertions
#     # ...
#   end

#   test "deleting a team and associated submissions and answers" do
#     # Test case for deleting a team along with its associated submissions and answers
#     # Set up the initial conditions
#     # ...

#     # Perform the assertions
#     # ...
#   end
end