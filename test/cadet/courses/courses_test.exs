defmodule Cadet.CoursesTest do
  use Cadet.DataCase

  alias Cadet.{Courses, Repo}
  alias Cadet.Courses.{Sourcecast, SourcecastUpload}

  describe "get course config" do
    test "succeeds" do
      course = insert(:course)
      insert(:assessment_type, %{order: 1, type: "Missions", course: course})
      insert(:assessment_type, %{order: 2, type: "Quests", course: course})

      {:ok, course} = Courses.get_course_config(course.id)
      assert course.course_name == "Programming Methodology"
      assert course.course_short_name == "CS1101S"
      assert course.viewable == true
      assert course.enable_game == true
      assert course.enable_achievements == true
      assert course.enable_sourcecast == true
      assert course.source_chapter == 1
      assert course.source_variant == "default"
      assert course.module_help_text == "Help Text"
      assert course.assessment_types == ["Missions", "Quests"]
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
          module_help_text: ""
        })

      assert updated_course.course_name == "Data Structures and Algorithms"
      assert updated_course.course_short_name == "CS2040S"
      assert updated_course.viewable == false
      assert updated_course.enable_game == false
      assert updated_course.enable_achievements == false
      assert updated_course.enable_sourcecast == false
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
      assert updated_course.source_chapter == new_chapter
      assert updated_course.source_variant == "default"
      assert updated_course.module_help_text == "help"
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

  describe "update assessment config" do
    test "succeeds" do
      course = insert(:course)
      type = insert(:assessment_type, %{course: course})
      _assessment_config = insert(:assessment_config, %{assessment_type: type})

      {:ok, updated_config} = Courses.update_assessment_config(course.id, type.order, 100, 24, 1)

      assert updated_config.early_submission_xp == 100
      assert updated_config.hours_before_early_xp_decay == 24
      assert updated_config.decay_rate_points_per_hour == 1
    end

    test "returns with error for failed updates" do
      course = insert(:course)
      type = insert(:assessment_type, %{course: course})
      _assessment_config = insert(:assessment_config, %{assessment_type: type})

      {:error, changeset} = Courses.update_assessment_config(course.id, type.order, -1, 0, 0)

      assert %{early_submission_xp: ["must be greater than or equal to 0"]} = errors_on(changeset)

      {:error, changeset} = Courses.update_assessment_config(course.id, type.order, 200, -1, 0)

      assert %{hours_before_early_xp_decay: ["must be greater than or equal to 0"]} =
               errors_on(changeset)

      {:error, changeset} = Courses.update_assessment_config(course.id, type.order, 200, 48, -1)

      assert %{decay_rate_points_per_hour: ["must be greater than or equal to 0"]} =
               errors_on(changeset)

      {:error, changeset} = Courses.update_assessment_config(course.id, type.order, 200, 48, 300)

      assert %{decay_rate_points_per_hour: ["must be less than or equal to 200"]} =
               errors_on(changeset)
    end
  end

  describe "update assessment types" do
    test "succeeds" do
      course = insert(:course)
      course_id = course.id

      insert(:assessment_type, %{order: 1, type: "Missions", course: course})
      insert(:assessment_type, %{order: 2, type: "Quests", course: course})
      insert(:assessment_type, %{order: 3, type: "Paths", course: course})
      insert(:assessment_type, %{order: 4, type: "Contests", course: course})
      insert(:assessment_type, %{order: 5, type: "Others", course: course})

      :ok =
        Courses.update_assessment_types(course_id, [
          "Paths",
          "Quests",
          "Missions",
          "Others",
          "Contests"
        ])

      {:ok, updated_course_config} = Courses.get_course_config(course_id)

      assert updated_course_config.assessment_types == [
               "Paths",
               "Quests",
               "Missions",
               "Others",
               "Contests"
             ]
    end

    test "succeeds when database entries are not in order" do
      course = insert(:course)
      course_id = course.id

      insert(:assessment_type, %{order: 4, type: "Contests", course: course})
      insert(:assessment_type, %{order: 1, type: "Missions", course: course})
      insert(:assessment_type, %{order: 3, type: "Paths", course: course})
      insert(:assessment_type, %{order: 5, type: "Others", course: course})
      insert(:assessment_type, %{order: 2, type: "Quests", course: course})

      :ok =
        Courses.update_assessment_types(course_id, [
          "Paths",
          "Quests",
          "Missions",
          "Others",
          "Contests"
        ])

      {:ok, updated_course_config} = Courses.get_course_config(course_id)

      assert updated_course_config.assessment_types == [
               "Paths",
               "Quests",
               "Missions",
               "Others",
               "Contests"
             ]
    end

    test "succeeds and capitalizes the types during database insertion" do
      course = insert(:course)
      course_id = course.id

      insert(:assessment_type, %{order: 1, type: "Missions", course: course})
      insert(:assessment_type, %{order: 2, type: "Quests", course: course})
      insert(:assessment_type, %{order: 3, type: "Paths", course: course})
      insert(:assessment_type, %{order: 4, type: "Contests", course: course})
      insert(:assessment_type, %{order: 5, type: "Others", course: course})

      :ok =
        Courses.update_assessment_types(course_id, [
          "Paths",
          "quests",
          "Missions",
          "Others",
          "contests"
        ])

      {:ok, updated_course_config} = Courses.get_course_config(course_id)

      assert updated_course_config.assessment_types == [
               "Paths",
               "Quests",
               "Missions",
               "Others",
               "Contests"
             ]
    end

    test "succeeds when inserting more types than existing database entries" do
      course = insert(:course)
      course_id = course.id

      insert(:assessment_type, %{order: 1, type: "Missions", course: course})
      insert(:assessment_type, %{order: 2, type: "Quests", course: course})
      insert(:assessment_type, %{order: 3, type: "Paths", course: course})

      :ok =
        Courses.update_assessment_types(course_id, [
          "Paths",
          "Quests",
          "Missions",
          "Others",
          "Contests"
        ])

      {:ok, updated_course_config} = Courses.get_course_config(course_id)

      assert updated_course_config.assessment_types == [
               "Paths",
               "Quests",
               "Missions",
               "Others",
               "Contests"
             ]
    end

    test "succeeds when inserting less types than existing database entries" do
      course = insert(:course)
      course_id = course.id

      insert(:assessment_type, %{order: 1, type: "Missions", course: course})
      insert(:assessment_type, %{order: 2, type: "Quests", course: course})
      insert(:assessment_type, %{order: 3, type: "Paths", course: course})
      insert(:assessment_type, %{order: 4, type: "Contests", course: course})

      :ok = Courses.update_assessment_types(course_id, ["Paths", "Quests", "Missions"])
      {:ok, updated_course_config} = Courses.get_course_config(course_id)

      assert updated_course_config.assessment_types == ["Paths", "Quests", "Missions"]
    end

    test "returns with error for invalid parameters" do
      course = insert(:course)
      course_id = course.id

      insert(:assessment_type, %{order: 1, type: "Missions", course: course})
      insert(:assessment_type, %{order: 2, type: "Quests", course: course})
      insert(:assessment_type, %{order: 3, type: "Paths", course: course})

      assert {:error, {:bad_request, "Invalid parameter(s)"}} =
               Courses.update_assessment_types(course_id, [1, "Quests", "Missions"])
    end

    test "returns with error for duplicate parameters" do
      course = insert(:course)
      course_id = course.id

      insert(:assessment_type, %{order: 1, type: "Missions", course: course})
      insert(:assessment_type, %{order: 2, type: "Quests", course: course})
      insert(:assessment_type, %{order: 3, type: "Paths", course: course})

      assert {:error, {:bad_request, "Invalid parameter(s)"}} =
               Courses.update_assessment_types(course_id, ["Missions", "Quests", "Missions"])
    end

    test "returns with error for empty list parameter" do
      course = insert(:course)
      course_id = course.id

      insert(:assessment_type, %{order: 1, type: "Missions", course: course})
      insert(:assessment_type, %{order: 2, type: "Quests", course: course})
      insert(:assessment_type, %{order: 3, type: "Paths", course: course})

      assert {:error, {:bad_request, "Invalid parameter(s)"}} =
               Courses.update_assessment_types(course_id, [])
    end

    test "returns with error for list parameter of greater than length 5" do
      course = insert(:course)
      course_id = course.id

      insert(:assessment_type, %{order: 1, type: "Missions", course: course})
      insert(:assessment_type, %{order: 2, type: "Quests", course: course})
      insert(:assessment_type, %{order: 3, type: "Paths", course: course})

      assert {:error, {:bad_request, "Invalid parameter(s)"}} =
               Courses.update_assessment_types(course_id, [
                 "Missions",
                 "Quests",
                 "Paths",
                 "Contests",
                 "Others",
                 "Assessments"
               ])
    end

    test "returns with error for non-list parameter" do
      course = insert(:course)
      course_id = course.id

      insert(:assessment_type, %{order: 1, type: "Missions", course: course})
      insert(:assessment_type, %{order: 2, type: "Quests", course: course})
      insert(:assessment_type, %{order: 3, type: "Paths", course: course})

      assert {:error, {:bad_request, "Invalid parameter(s)"}} =
               Courses.update_assessment_types(course_id, "Missions")
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

      deleter_course_registration = insert(:course_registration, %{role: :staff})
      assert {:ok, _} = Courses.delete_sourcecast_file(deleter_course_registration, sourcecast.id)
      assert Repo.get(Sourcecast, sourcecast.id) == nil
      refute File.exists?("uploads/test/sourcecasts/upload.wav")
    end
  end

  # describe "get_or_create_group" do
  #   test "existing group" do
  #     group = insert(:group)

  #     {:ok, group_db} = Courses.get_or_create_group(group.name)

  #     assert group_db.id == group.id
  #     assert group_db.leader_id == group.leader_id
  #   end

  #   test "non-existent group" do
  #     group_name = params_for(:group).name

  #     {:ok, _} = Courses.get_or_create_group(group_name)

  #     group_db =
  #       Group
  #       |> where(name: ^group_name)
  #       |> Repo.one()

  #     refute is_nil(group_db)
  #   end
  # end

  # describe "insert_or_update_group" do
  #   test "existing group" do
  #     group = insert(:group)
  #     group_params = params_with_assocs(:group, name: group.name)
  #     Courses.insert_or_update_group(group_params)

  #     updated_group =
  #       Group
  #       |> where(name: ^group.name)
  #       |> Repo.one()

  #     assert updated_group.id == group.id
  #     assert updated_group.leader_id == group_params.leader_id
  #   end

  #   test "non-existent group" do
  #     group_params = params_with_assocs(:group)
  #     Courses.insert_or_update_group(group_params)

  #     updated_group =
  #       Group
  #       |> where(name: ^group_params.name)
  #       |> Repo.one()

  #     assert updated_group.leader_id == group_params.leader_id
  #   end
  # end
end
