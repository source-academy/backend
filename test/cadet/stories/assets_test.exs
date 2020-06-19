defmodule Cadet.Stories.AssetsTest do
  alias Cadet.Stories.Assets

  use ExUnit.Case, async: true
  use ExVCR.Mock, adapter: ExVCR.Adapter.Hackney

  describe "Manage assets" do
    @tag authenticate: :staff
    test "accessible folder" do
      use_cassette "aws/list_assets#1" do
        assert Assets.list_assets("testFolder") === [
                 "testFolder/",
                 "testFolder/test.png",
                 "testFolder/test2.png"
               ]
      end
    end

    @tag authenticate: :staff
    test "delete folder" do
      use_cassette "aws/list_assets#2" do
        Assets.delete_object("testFolder", "test.png") === %{
          body: "",
          headers: [
            {"x-amz-id-2",
             "PncjVCgcIoTc49XZeP1eKwU7R5GPPP7zVObzP0c6JynZrMA5IcHy4g01pf481kMk1KKvvCVBm9g="},
            {"x-amz-request-id", "73264B10D3648604"},
            {"Date", "Fri, 19 Jun 2020 04:22:20 GMT"},
            {"Server", "AmazonS3"}
          ]
        }
      end
    end

    @tag authenticate: :staff
    test "upload file" do
      use_cassette "aws/list_assets#3" do
        Assets.delete_object("testFolder", "test.png") === %{
          body: "",
          headers: [
            {"x-amz-id-2",
             "/RAqIBt1jjZeK6U5HzIcKATQWZBSEoCVceZjrD0tZoguThCVAIwXn23UmReT1Tj4EEUb/AVwIew="},
            {"x-amz-request-id", "31DDB579F2CC548E"},
            {"Date", "Fri, 19 Jun 2020 04:26:33 GMT"},
            {"Server", "AmazonS3"}
          ],
          status_code: 204
        }
      end
    end
  end
end
