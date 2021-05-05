defmodule Cadet.Assets.AssetsTest do
  alias Cadet.Assets.Assets

  use ExUnit.Case, async: true
  use ExVCR.Mock, adapter: ExVCR.Adapter.Hackney

  describe "Manage assets" do
    test "accessible folder" do
      use_cassette "aws/model_list_assets#1" do
        assert Assets.list_assets("testFolder") === [
                 "testFolder/",
                 "testFolder/test.png",
                 "testFolder/test2.png"
               ]
      end
    end

    test "delete nonexistent file" do
      use_cassette "aws/model_delete_asset#1" do
        assert Assets.delete_object("testFolder", "test4.png") ===
                 {:error, {:not_found, "File not found"}}
      end
    end

    test "delete ok file" do
      use_cassette "aws/model_delete_asset#2" do
        assert Assets.delete_object("testFolder", "test.png") === :ok
      end
    end

    test "upload existing file" do
      use_cassette "aws/model_upload_asset#1" do
        assert Assets.upload_to_s3(
                 build_upload("test/fixtures/upload.png"),
                 "testFolder",
                 "test2.png"
               ) ===
                 {:error, {:bad_request, "File already exists"}}
      end
    end

    test "upload ok file" do
      use_cassette "aws/model_upload_asset#2" do
        assert Assets.upload_to_s3(
                 build_upload("test/fixtures/upload.png"),
                 "testFolder",
                 "test1.png"
               ) ===
                 "https://source-academy-assets.s3.amazonaws.com/testFolder/test1.png"
      end
    end
  end

  defp build_upload(path, content_type \\ "image\png") do
    %Plug.Upload{path: path, filename: Path.basename(path), content_type: content_type}
  end
end
