defmodule Cadet.Chatbot.DocumentUploaderTest do
  use ExUnit.Case

  import ExUnit.CaptureLog
  import Mock

  alias Cadet.Chatbot.DocumentUploader

  @moduletag :serial
  test "upload/4 rejects a file over the size limit without touching S3" do
    path = Path.join(System.tmp_dir!(), "oversized-#{System.unique_integer([:positive])}.pdf")
    File.write!(path, :binary.copy(<<0>>, 10_000_001))
    on_exit(fn -> File.rm(path) end)

    with_mock ExAws, [:passthrough], request: fn _operation, _options -> {:ok, %{}} end do
      assert {:error, {:bad_request, message}} =
               DocumentUploader.upload("lecture.pdf", path, 1)

      assert message =~ "10.0 MB limit"
      refute called(ExAws.request(:_, :_))
    end
  end

  test "upload/4 rejects an unsupported extension before stat'ing the file" do
    assert {:error, {:bad_request, "Unsupported file type .exe"}} =
             DocumentUploader.upload("malware.exe", "/nonexistent/path", 1)
  end

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
