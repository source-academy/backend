defmodule Cadet.CourseTest do
  use Cadet.DataCase

  alias Cadet.{Course, Repo}
  alias Cadet.Course.{Group, Material, Sourcecast, Upload}

  describe "Material" do
    setup do
      on_exit(fn -> File.rm_rf!("uploads/test/materials") end)
    end

    test "create root folder valid" do
      uploader = insert(:user, %{role: :staff})

      result =
        Course.create_material_folder(uploader, %{
          name: "Lecture Notes",
          description: "This is where the notes"
        })

      assert {:ok, material} = result
      assert material.uploader == uploader
      assert material.name == "Lecture Notes"
      assert material.description == "This is where the notes"
    end

    test "create folder with parent valid" do
      parent = insert(:material_folder)
      uploader = insert(:user, %{role: :staff})

      result =
        Course.create_material_folder(parent, uploader, %{
          name: "Lecture Notes"
        })

      assert {:ok, material} = result
      assert material.parent_id == parent.id
    end

    test "create folder invalid" do
      uploader = insert(:user, %{role: :staff})

      assert {:error, changeset} =
               Course.create_material_folder(uploader, %{
                 name: ""
               })

      assert errors_on(changeset) == %{
               name: ["can't be blank"]
             }
    end

    test "upload file to folder then delete it" do
      uploader = insert(:user, %{role: :staff})
      folder = insert(:material_folder)

      upload = %Plug.Upload{
        content_type: "text/plain",
        filename: "upload.txt",
        path: "test/fixtures/upload.txt"
      }

      result =
        Course.upload_material_file(folder, uploader, %{
          name: "Test Upload",
          file: upload
        })

      assert {:ok, material} = result
      path = Upload.url({material.file, material})
      assert path =~ "/uploads/test/materials/upload.txt"

      assert {:ok, _} = Course.delete_material(material)
      assert Repo.get(Material, material.id) == nil
      refute File.exists?("uploads/test/materials/upload.txt")
    end

    test "list folder content" do
      folder = insert(:material_folder)
      folder2 = insert(:material_folder, %{parent: folder})
      _ = insert(:material_file, %{parent: folder2})
      _ = insert(:material_file, %{parent: folder2})
      file3 = insert(:material_file, %{parent: folder})

      result = Course.list_material_folders(folder)

      assert Enum.count(result) == 2

      set =
        result
        |> Enum.map(& &1.id)
        |> MapSet.new()

      assert MapSet.member?(set, folder2.id)
      assert MapSet.member?(set, file3.id)
    end

    test "delete a folder" do
      folder = insert(:material_folder)
      folder2 = insert(:material_folder, %{parent: folder})
      file1 = insert(:material_file, %{parent: folder2})
      file2 = insert(:material_file, %{parent: folder2})
      file3 = insert(:material_file, %{parent: folder})

      assert {:ok, _} = Course.delete_material(folder.id)

      [file1, file2, file3, folder, folder2]
      |> Enum.each(&assert(Repo.get(Material, &1.id) == nil))
    end
  end

  describe "Sourcecast" do
    setup do
      on_exit(fn -> File.rm_rf!("uploads/test/materials") end)
    end

    test "upload file to folder then delete it" do
      uploader = insert(:user, %{role: :staff})

      upload = %Plug.Upload{
        content_type: "audio/wav",
        filename: "upload.wav",
        path: "test/fixtures/upload.wav"
      }

      result =
        Course.upload_sourcecast_file(uploader, %{
          title: "Test Upload",
          audio: upload,
          playbackData:
            "{\"init\":{\"editorValue\":\"// Type your program in here!\"},\"inputs\":[]}"
        })

      assert {:ok, sourcecast} = result
      path = Upload.url({sourcecast.audio, sourcecast})
      assert path =~ "/uploads/test/materials/upload.wav"

      deleter = insert(:user, %{role: :staff})
      assert {:ok, _} = Course.delete_sourcecast_file(deleter, sourcecast.id)
      assert Repo.get(Sourcecast, sourcecast.id) == nil
      refute File.exists?("uploads/test/materials/upload.wav")
    end
  end

  describe "get_or_create_group" do
    test "existing group" do
      group = insert(:group)

      {:ok, group_db} = Course.get_or_create_group(group.name)

      assert group_db.id == group.id
      assert group_db.leader_id == group.leader_id
    end

    test "non-existent group" do
      group_name = params_for(:group).name

      {:ok, _} = Course.get_or_create_group(group_name)

      group_db =
        Group
        |> where(name: ^group_name)
        |> Repo.one()

      refute is_nil(group_db)
    end
  end

  describe "insert_or_update_group" do
    test "existing group" do
      group = insert(:group)
      group_params = params_with_assocs(:group, name: group.name)
      Course.insert_or_update_group(group_params)

      updated_group =
        Group
        |> where(name: ^group.name)
        |> Repo.one()

      assert updated_group.id == group.id
      assert updated_group.leader_id == group_params.leader_id
    end

    test "non-existent group" do
      group_params = params_with_assocs(:group)
      Course.insert_or_update_group(group_params)

      updated_group =
        Group
        |> where(name: ^group_params.name)
        |> Repo.one()

      assert updated_group.leader_id == group_params.leader_id
    end
  end
end
