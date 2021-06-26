defmodule Cadet.CoursesTest do
  use Cadet.DataCase

  alias Cadet.{Courses, Repo}
  alias Cadet.Courses.{Sourcecast, SourcecastUpload}

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
      assert length(old_configs) == 0
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

  describe "delete_assessment_config" do
    test "succeeds" do
      course = insert(:course)
      config = insert(:assessment_config, %{order: 1, course: course})
      old_configs = Courses.get_assessment_configs(course.id)

      params = %{
        assessment_config_id: config.id
      }

      {:ok, _} = Courses.delete_assessment_config(course.id, params)

      new_configs = Courses.get_assessment_configs(course.id)
      assert length(old_configs) == 1
      assert length(new_configs) == 0
    end

    test "error" do
      course = insert(:course)
      insert(:assessment_config, %{order: 1, course: course})

      params = %{
        assessment_config_id: -1
      }

      assert {:error, :no_such_enrty} == Courses.delete_assessment_config(course.id, params)
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
