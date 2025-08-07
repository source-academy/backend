defmodule Cadet.CoursesTest do
  use Cadet.DataCase

  alias Cadet.{Courses, Repo}
  alias Cadet.Accounts.{CourseRegistration, User}
  alias Cadet.Courses.{Course, Group, Sourcecast, SourcecastUpload}
  alias Cadet.Assessments.Assessment

  describe "create course config" do
    test "succeeds" do
      user = insert(:user)

      # Course precreated in User factory
      old_courses = Course |> Repo.all() |> length()

      params = %{
        course_name: "CS1101S Programming Methodology (AY20/21 Sem 1)",
        course_short_name: "CS1101S",
        viewable: true,
        enable_game: true,
        enable_achievements: true,
        enable_overall_leaderboard: true,
        enable_contest_leaderboard: true,
        top_leaderboard_display: 100,
        top_contest_leaderboard_display: 10,
        enable_sourcecast: true,
        enable_stories: false,
        source_chapter: 1,
        source_variant: "default",
        module_help_text: "Help Text"
      }

      Courses.create_course_config(params, user)

      # New course created
      new_courses = Course |> Repo.all() |> length()
      assert new_courses - old_courses == 1

      # New admin course registration for user
      course_regs = CourseRegistration |> where(user_id: ^user.id) |> Repo.all()
      assert length(course_regs) == 1
      assert Enum.at(course_regs, 0).role == :admin

      # User's latest_viewed_course is updated
      assert User |> where(id: ^user.id) |> Repo.one() |> Map.fetch!(:latest_viewed_course_id) ==
               Enum.at(course_regs, 0).course_id
    end
  end

  describe "get course config" do
    test "succeeds" do
      course = insert(:course)
      insert(:assessment_config, %{order: 1, type: "Missions", course: course})
      insert(:assessment_config, %{order: 2, type: "Quests", course: course})

      {:ok, course} = Courses.get_course_config(course.id)
      assert course.course_name == "Programming Methodology"
      assert course.course_short_name == "CS1101S"
      assert course.viewable == true
      assert course.enable_game == true
      assert course.enable_achievements == true
      assert course.enable_sourcecast == true
      assert course.enable_stories == false
      assert course.source_chapter == 1
      assert course.source_variant == "default"
      assert course.module_help_text == "Help Text"
      assert course.assessment_configs == ["Missions", "Quests"]
    end

    test "returns with error for invalid course id" do
      course = insert(:course)

      assert {:error, {:bad_request, "Invalid course id"}} =
               Courses.get_course_config(course.id + 1)
    end
  end

  describe "update course config" do
    test "succeeds (without sublanguage update)" do
      course = insert(:course)

      {:ok, updated_course} =
        Courses.update_course_config(course.id, %{
          course_name: "Data Structures and Algorithms",
          course_short_name: "CS2040S",
          viewable: false,
          enable_game: false,
          enable_achievements: false,
          enable_sourcecast: false,
          enable_stories: true,
          module_help_text: ""
        })

      assert updated_course.course_name == "Data Structures and Algorithms"
      assert updated_course.course_short_name == "CS2040S"
      assert updated_course.viewable == false
      assert updated_course.enable_game == false
      assert updated_course.enable_achievements == false
      assert updated_course.enable_sourcecast == false
      assert updated_course.enable_stories == true
      assert updated_course.source_chapter == 1
      assert updated_course.source_variant == "default"
      assert updated_course.module_help_text == nil
    end

    test "succeeds (with sublanguage update)" do
      course = insert(:course)
      new_chapter = Enum.random(1..4)

      {:ok, updated_course} =
        Courses.update_course_config(course.id, %{
          course_name: "Data Structures and Algorithms",
          course_short_name: "CS2040S",
          viewable: false,
          enable_game: false,
          enable_achievements: false,
          enable_sourcecast: false,
          enable_stories: true,
          source_chapter: new_chapter,
          source_variant: "default",
          module_help_text: "help"
        })

      assert updated_course.course_name == "Data Structures and Algorithms"
      assert updated_course.course_short_name == "CS2040S"
      assert updated_course.viewable == false
      assert updated_course.enable_game == false
      assert updated_course.enable_achievements == false
      assert updated_course.enable_sourcecast == false
      assert updated_course.enable_stories == true
      assert updated_course.source_chapter == new_chapter
      assert updated_course.source_variant == "default"
      assert updated_course.module_help_text == "help"
    end

    test "succeeds (removes latest_viewed_course_id)" do
      course = insert(:course)
      user = insert(:user, %{latest_viewed_course: course})

      {:ok, updated_course} =
        Courses.update_course_config(course.id, %{
          course_name: "Data Structures and Algorithms",
          course_short_name: "CS2040S",
          viewable: false,
          enable_game: false,
          enable_achievements: false,
          enable_sourcecast: false,
          enable_stories: false,
          module_help_text: "help"
        })

      assert updated_course.viewable == false
      assert is_nil(Repo.get(User, user.id).latest_viewed_course_id)
    end

    test "returns with error for invalid course id" do
      course = insert(:course)
      new_chapter = Enum.random(1..4)

      assert {:error, {:bad_request, "Invalid course id"}} =
               Courses.update_course_config(course.id + 1, %{
                 source_chapter: new_chapter,
                 source_variant: "default"
               })
    end

    test "returns with error for failed updates" do
      course = insert(:course)

      assert {:error, changeset} =
               Courses.update_course_config(course.id, %{
                 source_chapter: 0,
                 source_variant: "default"
               })

      assert %{source_chapter: ["is invalid"]} = errors_on(changeset)

      assert {:error, changeset} =
               Courses.update_course_config(course.id, %{source_chapter: 2, source_variant: "gpu"})

      assert %{source_variant: ["is invalid"]} = errors_on(changeset)
    end
  end

  describe "get assessment configs" do
    test "succeeds" do
      course = insert(:course)

      for i <- 1..5 do
        insert(:assessment_config, %{order: 6 - i, type: "Mission#{i}", course: course})
      end

      assessment_configs = Courses.get_assessment_configs(course.id)

      assert length(assessment_configs) <= 5

      assessment_configs
      |> Enum.with_index(1)
      |> Enum.each(fn {at, idx} ->
        assert at.order == idx
        assert at.type == "Mission#{6 - idx}"
      end)
    end
  end

  describe "mass_upsert_and_reorder_assessment_configs" do
    setup do
      course = insert(:course)
      config1 = insert(:assessment_config, %{order: 1, type: "Missions", course: course})
      config2 = insert(:assessment_config, %{order: 2, type: "Quests", course: course})
      config3 = insert(:assessment_config, %{order: 3, type: "Paths", course: course})
      config4 = insert(:assessment_config, %{order: 4, type: "Contests", course: course})
      expected = ["Paths", "Quests", "Missions", "Others", "Contests"]

      {:ok,
       %{
         course: course,
         expected: expected,
         config1: config1,
         config2: config2,
         config3: config3,
         config4: config4
       }}
    end

    test "succeeds", %{
      course: course,
      expected: expected,
      config1: config1,
      config2: config2,
      config3: config3,
      config4: config4
    } do
      {:ok, _} =
        Courses.mass_upsert_and_reorder_assessment_configs(course.id, [
          %{assessment_config_id: config1.id, type: "Paths"},
          %{assessment_config_id: config2.id, type: "Quests"},
          %{assessment_config_id: config3.id, type: "Missions"},
          %{assessment_config_id: config4.id, type: "Others"},
          %{assessment_config_id: -1, type: "Contests"}
        ])

      assessment_configs = Courses.get_assessment_configs(course.id)

      assert Enum.map(assessment_configs, & &1.type) == expected
    end

    test "succeeds to capitalise", %{
      course: course,
      expected: expected,
      config1: config1,
      config2: config2,
      config3: config3,
      config4: config4
    } do
      {:ok, _} =
        Courses.mass_upsert_and_reorder_assessment_configs(course.id, [
          %{assessment_config_id: config1.id, type: "Paths"},
          %{assessment_config_id: config2.id, type: "Quests"},
          %{assessment_config_id: config3.id, type: "Missions"},
          %{assessment_config_id: config4.id, type: "Others"},
          %{assessment_config_id: -1, type: "Contests"}
        ])

      assessment_configs = Courses.get_assessment_configs(course.id)

      assert Enum.map(assessment_configs, & &1.type) == expected
    end

    # test "succeed to delete", %{course: course} do
    #   :ok =
    #     Courses.mass_upsert_and_reorder_assessment_configs(course.id, [
    #       %{order: 1, type: "Paths"},
    #       %{order: 2, type: "quests"},
    #       %{order: 3, type: "missions"}
    #     ])

    #   assessment_configs = Courses.get_assessment_configs(course.id)

    #   assert Enum.map(assessment_configs, & &1.type) == ["Paths", "Quests", "Missions"]
    # end

    test "returns with error for empty list parameter", %{course: course} do
      assert {:error, {:bad_request, "Invalid parameter(s)"}} =
               Courses.mass_upsert_and_reorder_assessment_configs(course.id, [])
    end

    test "returns with error for list parameter of greater than length 8", %{
      course: course,
      config1: config1,
      config2: config2,
      config3: config3,
      config4: config4
    } do
      params = [
        %{assessment_config_id: config1.id, type: "Paths"},
        %{assessment_config_id: config2.id, type: "Quests"},
        %{assessment_config_id: config3.id, type: "Missions"},
        %{assessment_config_id: config4.id, type: "Others"},
        %{assessment_config_id: -1, type: "Contests"},
        %{assessment_config_id: -1, type: "Contests"},
        %{assessment_config_id: -1, type: "Contests"},
        %{assessment_config_id: -1, type: "Contests"},
        %{assessment_config_id: -1, type: "Contests"}
      ]

      assert {:error, {:bad_request, "Invalid parameter(s)"}} =
               Courses.mass_upsert_and_reorder_assessment_configs(course.id, params)
    end

    test "returns with error for non-list parameter", %{course: course} do
      params = %{course_id: course.id, order: 1, type: "Paths"}

      assert {:error, {:bad_request, "Invalid parameter(s)"}} =
               Courses.mass_upsert_and_reorder_assessment_configs(course.id, params)
    end
  end

  describe "insert_or_update_assessment_config" do
    test "succeeds with insert configs" do
      course = insert(:course)
      old_configs = Courses.get_assessment_configs(course.id)

      params = %{
        assessment_config_id: -1,
        order: 1,
        type: "Mission",
        early_submission_xp: 100,
        hours_before_early_xp_decay: 24
      }

      {:ok, updated_config} = Courses.insert_or_update_assessment_config(course.id, params)

      new_configs = Courses.get_assessment_configs(course.id)
      assert old_configs == []
      assert length(new_configs) == 1
      assert updated_config.early_submission_xp == 100
      assert updated_config.hours_before_early_xp_decay == 24
    end

    test "succeeds with update" do
      course = insert(:course)
      config = insert(:assessment_config, %{course: course})

      params = %{
        assessment_config_id: config.id,
        type: "Mission",
        early_submission_xp: 100,
        hours_before_early_xp_decay: 24
      }

      {:ok, updated_config} = Courses.insert_or_update_assessment_config(course.id, params)

      assert updated_config.type == "Mission"
      assert updated_config.early_submission_xp == 100
      assert updated_config.hours_before_early_xp_decay == 24
    end
  end

  describe "reorder_assessment_config" do
    test "succeeds" do
      course = insert(:course)
      config1 = insert(:assessment_config, %{order: 1, type: "Missions", course: course})
      config3 = insert(:assessment_config, %{order: 2, type: "Paths", course: course})
      config2 = insert(:assessment_config, %{order: 3, type: "Quests", course: course})
      config4 = insert(:assessment_config, %{order: 4, type: "Others", course: course})
      old_configs = Courses.get_assessment_configs(course.id)

      params = [
        %{assessment_config_id: config1.id, type: "Paths"},
        %{assessment_config_id: config2.id, type: "Quests"},
        %{assessment_config_id: config3.id, type: "Missions"},
        %{assessment_config_id: config4.id, type: "Others"}
      ]

      expected = ["Paths", "Quests", "Missions", "Others"]

      {:ok, _} = Courses.reorder_assessment_configs(course.id, params)

      new_configs = Courses.get_assessment_configs(course.id)
      assert length(old_configs) == length(new_configs)
      assert Enum.map(new_configs, & &1.type) == expected
    end
  end

  describe "delete_assessment_config" do
    test "succeeds" do
      course = insert(:course)
      config = insert(:assessment_config, %{order: 1, course: course})
      assessment = insert(:assessment, %{course: course, config: config})
      old_configs = Courses.get_assessment_configs(course.id)
      refute Assessment |> Repo.get(assessment.id) |> is_nil()

      {:ok, _} = Courses.delete_assessment_config(course.id, config.id)

      new_configs = Courses.get_assessment_configs(course.id)
      assert length(old_configs) == 1
      assert new_configs == []
      assert Assessment |> Repo.get(assessment.id) |> is_nil()
    end

    test "error" do
      course = insert(:course)
      insert(:assessment_config, %{order: 1, course: course})

      assert {:error, "The given assessment configuration does not exist"} ==
               Courses.delete_assessment_config(course.id, -1)
    end
  end

  describe "upsert_groups_in_course" do
    setup do
      course = insert(:course)
      existing_group_leader = insert(:course_registration, %{course: course, role: :staff})

      existing_group =
        insert(:group, %{name: "Existing Group", course: course, leader: existing_group_leader})

      existing_student =
        insert(:course_registration, %{course: course, group: existing_group, role: :student})

      {:ok,
       course: course,
       existing_group: existing_group,
       existing_group_leader: existing_group_leader,
       existing_student: existing_student}
    end

    test "succeeds in upserting existing groups", %{
      course: course,
      existing_group: existing_group,
      existing_group_leader: existing_group_leader,
      existing_student: existing_student
    } do
      student = insert(:course_registration, %{course: course, group: nil, role: :student})
      admin = insert(:course_registration, %{course: course, group: nil, role: :admin})

      usernames_and_groups = [
        %{username: existing_student.user.username, group: "Group1"},
        %{username: admin.user.username, group: "Group2"},
        %{username: student.user.username, group: "Group2"},
        %{username: existing_group_leader.user.username, group: "Group1"}
      ]

      assert :ok == Courses.upsert_groups_in_course(usernames_and_groups, course.id, "test")

      # Check that Group1 and Group2 were created
      assert length(Group |> where(course_id: ^course.id) |> Repo.all()) == 3

      # Check that leaders were assigned/ updated correctly
      assert is_nil(
               Group
               |> where(id: ^existing_group.id)
               |> Repo.one()
               |> Map.fetch!(:leader_id)
             )

      group1 = Group |> where(course_id: ^course.id) |> where(name: "Group1") |> Repo.one()
      group2 = Group |> where(course_id: ^course.id) |> where(name: "Group2") |> Repo.one()
      assert group1 |> Map.fetch!(:leader_id) == existing_group_leader.id
      assert group2 |> Map.fetch!(:leader_id) == admin.id

      # Check that students were assigned to the correct groups
      assert CourseRegistration
             |> where(id: ^existing_student.id)
             |> Repo.one()
             |> Map.fetch!(:group_id) ==
               group1.id

      assert CourseRegistration |> where(id: ^student.id) |> Repo.one() |> Map.fetch!(:group_id) ==
               group2.id
    end

    test "succeeds (removes user from existing groups when group is not specified)", %{
      course: course,
      existing_group: existing_group,
      existing_group_leader: existing_group_leader,
      existing_student: existing_student
    } do
      usernames_and_groups = [
        %{username: existing_student.user.username},
        %{username: existing_group_leader.user.username}
      ]

      assert :ok == Courses.upsert_groups_in_course(usernames_and_groups, course.id, "test")

      assert is_nil(
               Group
               |> where(id: ^existing_group.id)
               |> Repo.one()
               |> Map.fetch!(:leader_id)
             )

      assert is_nil(
               CourseRegistration
               |> where(id: ^existing_student.id)
               |> Repo.one()
               |> Map.fetch!(:group_id)
             )
    end

    test "succeeds when upsert same group name to another course", %{
      course: course,
      existing_group_leader: existing_group_leader
    } do
      course2 = insert(:course)

      new_group_leader = insert(:course_registration, %{course: course2, role: :staff})
      new_group_student = insert(:course_registration, %{course: course2, role: :student})

      assert is_nil(
               Group
               |> where(course_id: ^course2.id)
               |> where(name: "Existing Group")
               |> Repo.one()
             )

      usernames_and_groups = [
        %{username: new_group_student.user.username, group: "Existing Group"},
        %{username: new_group_leader.user.username, group: "Existing Group"}
      ]

      assert :ok == Courses.upsert_groups_in_course(usernames_and_groups, course2.id, "test")

      group = Group |> where(course_id: ^course.id) |> where(name: "Existing Group") |> Repo.one()
      assert group |> Map.fetch!(:leader_id) == existing_group_leader.id

      group2 =
        Group |> where(course_id: ^course2.id) |> where(name: "Existing Group") |> Repo.one()

      assert group2 |> Map.fetch!(:leader_id) == new_group_leader.id

      student = CourseRegistration |> Repo.get(new_group_student.id)
      assert student |> Map.fetch!(:group_id) == group2.id

      leader = CourseRegistration |> Repo.get(new_group_leader.id)
      assert leader |> Map.fetch!(:group_id) == group2.id

      # test on update idempotence
      usernames_and_groups2 = [
        %{username: new_group_leader.user.username, group: "Existing Group"}
      ]

      assert :ok == Courses.upsert_groups_in_course(usernames_and_groups2, course2.id, "test")

      group2 =
        Group |> where(course_id: ^course2.id) |> where(name: "Existing Group") |> Repo.one()

      assert group2 |> Map.fetch!(:leader_id) == new_group_leader.id
    end
  end

  describe "Sourcecast" do
    setup do
      on_exit(fn -> File.rm_rf!("uploads/test/sourcecasts") end)
    end

    test "upload file to folder then delete it" do
      inserter_course_registration = insert(:course_registration, %{role: :staff})

      upload = %Plug.Upload{
        content_type: "audio/wav",
        filename: "upload.wav",
        path: "test/fixtures/upload.wav"
      }

      result =
        Courses.upload_sourcecast_file(inserter_course_registration, %{
          title: "Test Upload",
          audio: upload,
          playbackData:
            "{\"init\":{\"editorValue\":\"// Type your program in here!\"},\"inputs\":[]}"
        })

      assert {:ok, sourcecast} = result
      path = SourcecastUpload.url({sourcecast.audio, sourcecast})
      assert path =~ "/uploads/test/sourcecasts/upload.wav"

      assert {:ok, _} = Courses.delete_sourcecast_file(sourcecast.id)
      assert Repo.get(Sourcecast, sourcecast.id) == nil
      refute File.exists?("uploads/test/sourcecasts/upload.wav")
    end
  end

  describe "get_or_create_group" do
    test "existing group" do
      course = insert(:course)
      group = insert(:group, %{course: course})

      {:ok, group_db} = Courses.get_or_create_group(group.name, course.id)

      assert group_db.id == group.id
      assert group_db.leader_id == group.leader_id
    end

    test "non-existent group" do
      course = insert(:course)
      group_name = params_for(:group).name

      {:ok, _} = Courses.get_or_create_group(group_name, course.id)

      group_db =
        Group
        |> where(name: ^group_name)
        |> Repo.one()

      refute is_nil(group_db)
    end
  end
end
