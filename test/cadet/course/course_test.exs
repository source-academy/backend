defmodule Cadet.CourseTest do
  use Cadet.DataCase

  alias Cadet.{Course, Repo}
  alias Cadet.Courses.{Group, Sourcecast, SourcecastUpload}

  describe "Sourcecast" do
    setup do
      on_exit(fn -> File.rm_rf!("uploads/test/sourcecasts") end)
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
      path = SourcecastUpload.url({sourcecast.audio, sourcecast})
      assert path =~ "/uploads/test/sourcecasts/upload.wav"

      deleter = insert(:user, %{role: :staff})
      assert {:ok, _} = Course.delete_sourcecast_file(deleter, sourcecast.id)
      assert Repo.get(Sourcecast, sourcecast.id) == nil
      refute File.exists?("uploads/test/sourcecasts/upload.wav")
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
