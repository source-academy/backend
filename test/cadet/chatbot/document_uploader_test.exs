defmodule Cadet.Chatbot.DocumentUploaderTest do
  use ExUnit.Case

  import ExUnit.CaptureLog
  import Mock

  alias Cadet.Chatbot.DocumentUploader

  @moduletag :serial

  test "rename/3 returns the old key without probing S3 when the filename is unchanged" do
    assert {:ok, %{s3_key: "course-1/notes.pdf"}} =
             DocumentUploader.rename("course-1/notes.pdf", "notes.pdf", 1)
  end

  test "rename/3 treats non-404 head errors as occupied" do
    parent = self()

    with_mock ExAws, [:passthrough],
      request: fn _operation, _options ->
        count = Process.get(:request_count, 0)
        Process.put(:request_count, count + 1)
        send(parent, {:request, count})

        case count do
          0 -> {:error, :timeout}
          1 -> {:error, {:http_error, 404, %{}}}
          _ -> {:ok, %{}}
        end
      end do
      capture_log(fn ->
        assert {:ok, %{s3_key: "course-1/new-1.pdf"}} =
                 DocumentUploader.rename("course-1/old.pdf", "new.pdf", 1)
      end)

      assert_receive {:request, 0}
      assert_receive {:request, 1}
      assert_receive {:request, 2}
      assert_receive {:request, 3}
    end
  end
end
