defmodule Cadet.CourseTest do
  use Cadet.DataCase

  alias Cadet.{Course, Repo}
  alias Cadet.Course.{Material, Upload}

  describe "Announcements" do
    test "create valid" do
      poster = insert(:user)

      assert {:ok, announcement} =
               Course.create_announcement(poster, %{
                 title: "Test",
                 content: "Some content"
               })

      assert announcement.title == "Test"
      assert announcement.content == "Some content"
    end

    test "create invalid" do
      poster = insert(:user)

      assert {:error, changeset} =
               Course.create_announcement(poster, %{
                 title: "",
                 content: "Some content"
               })

      assert errors_on(changeset) == %{title: ["can't be blank"]}
    end

    test "edit valid" do
      announcement = insert(:announcement)

      assert {:ok, announcement} =
               Course.edit_announcement(announcement.id, %{title: "New title", pinned: true})

      assert announcement.title == "New title"
      assert announcement.pinned
    end

    test "get valid" do
      announcement = insert(:announcement)
      assert announcement == Course.get_announcement(announcement.id)
    end

    test "edit invalid" do
      announcement = insert(:announcement)
      assert {:error, changeset} = Course.edit_announcement(announcement.id, %{title: ""})
      assert errors_on(changeset) == %{title: ["can't be blank"]}
    end

    test "edit not found" do
      assert {:error, :not_found} = Course.edit_announcement(255, %{})
    end

    test "delete valid" do
      announcement = insert(:announcement)
      assert {:ok, _} = Course.delete_announcement(announcement.id)
    end

    test "delete not found" do
      assert {:error, :not_found} = Course.delete_announcement(255)
    end
  end

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
end
