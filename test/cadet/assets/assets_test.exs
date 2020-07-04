defmodule Cadet.Assets.AssetsTest do
  alias Cadet.Assets.Assets
  alias Cadet.Accounts.User

  use ExUnit.Case, async: true
  use ExVCR.Mock, adapter: ExVCR.Adapter.Hackney

  describe "Manage assets" do
    @tag authenticate: :staff
    test "accessible folder" do
      use_cassette "aws/model_list_assets#1" do
        assert Assets.list_assets("testFolder", %User{role: :staff}) === [
                 "testFolder/",
                 "testFolder/test.png",
                 "testFolder/test2.png"
               ]
      end
    end

    @tag authenticate: :staff
    test "delete nonexistent file" do
      use_cassette "aws/model_delete_asset#1" do
        assert Assets.delete_object("testFolder", "test4.png", %User{role: :staff}) ===
                 {:error, {:not_found, "File not found"}}
      end
    end

    @tag authenticate: :staff
    test "delete ok file" do
      use_cassette "aws/model_delete_asset#2" do
        assert Assets.delete_object("testFolder", "test.png", %User{role: :staff}) === :ok
      end
    end

    @tag authenticate: :staff
    test "upload existing file" do
      use_cassette "aws/model_upload_asset#1" do
        assert Assets.upload_to_s3(
                 build_upload("test/fixtures/upload.png"),
                 "testFolder",
                 "test2.png",
                 %User{role: :staff}
               ) ===
                 {:error, {:bad_request, "File already exists"}}
      end
    end

    @tag authenticate: :staff
    test "upload ok file" do
      use_cassette "aws/model_upload_asset#2" do
        assert Assets.upload_to_s3(
                 build_upload("test/fixtures/upload.png"),
                 "testFolder",
                 "test1.png",
                 %User{role: :staff}
               ) ===
                 "https://source-academy-assets.s3.amazonaws.com/testFolder/test1.png"
      end
    end
  end

  defp build_upload(path, content_type \\ "image\png") do
    %Plug.Upload{path: path, filename: Path.basename(path), content_type: content_type}
  end
end
