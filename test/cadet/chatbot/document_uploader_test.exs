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

  # The message names the offending type and what would have been accepted, so an admin who picked
  # the wrong file out of a folder can see which one and what to convert it to.
  test "upload/4 rejects an unsupported extension before stat'ing the file" do
    assert {:error, {:bad_request, message}} =
             DocumentUploader.upload("malware.exe", "/nonexistent/path", 1)

    assert message ==
             ".exe files are not supported. Accepted file types are .pdf, .pptx, .docx, .tex, .xml."
  end

  test "upload/4 says so when the file has no extension at all" do
    assert {:error, {:bad_request, message}} =
             DocumentUploader.upload("lecture-notes", "/nonexistent/path", 1)

    assert message =~ "Files must have an extension"
    assert message =~ ".pdf"
  end

  test "accepted_types_sentence/0 lists every extension upload/4 accepts" do
    sentence = DocumentUploader.accepted_types_sentence()

    for ext <- DocumentUploader.accepted_extensions() do
      assert sentence =~ ext
    end
  end

  test "rename/3 returns the old key without probing S3 when the filename is unchanged" do
    assert {:ok, %{s3_key: "course-1/notes.pdf"}} =
             DocumentUploader.rename("course-1/notes.pdf", "notes.pdf", 1)
  end

  test "upload/4 stores the file under a slug of its name and reports the media type" do
    path = write_temp("lecture 1a.pdf", "PDF bytes")
    parent = self()

    with_mock ExAws, [:passthrough],
      request: fn operation, _options ->
        send(parent, {:request, operation.http_method, operation.path})
        # No object exists yet, so the head probe 404s and the slug is free.
        if operation.http_method == :head, do: {:error, {:http_error, 404, %{}}}, else: {:ok, %{}}
      end do
      assert {:ok, %{s3_key: "course-7/lecture-1a.pdf", media_type: "application/pdf"}} =
               DocumentUploader.upload("lecture 1a.pdf", path, 7)

      assert_receive {:request, :head, _}
      assert_receive {:request, :put, "course-7/lecture-1a.pdf"}
    end
  end

  # Two files with the same name in one course would otherwise overwrite each other in S3.
  test "upload/4 suffixes a key already taken by an object in the bucket" do
    path = write_temp("l1a.pdf", "PDF bytes")

    with_mock ExAws, [:passthrough],
      request: fn operation, _options ->
        cond do
          operation.http_method != :head -> {:ok, %{}}
          operation.path == "course-7/l1a.pdf" -> {:ok, %{}}
          true -> {:error, {:http_error, 404, %{}}}
        end
      end do
      assert {:ok, %{s3_key: "course-7/l1a-1.pdf"}} =
               DocumentUploader.upload("l1a.pdf", path, 7)
    end
  end

  # Within one multi-file upload the earlier files are not in S3 yet, so the head probe would say
  # every one of them is free and they would all land on the same key.
  test "upload/4 avoids keys already claimed earlier in the same batch" do
    path = write_temp("l1a.pdf", "PDF bytes")

    with_mock ExAws, [:passthrough],
      request: fn operation, _options ->
        if operation.http_method == :head, do: {:error, {:http_error, 404, %{}}}, else: {:ok, %{}}
      end do
      claimed = MapSet.new(["course-7/l1a.pdf"])

      assert {:ok, %{s3_key: "course-7/l1a-1.pdf"}} =
               DocumentUploader.upload("l1a.pdf", path, 7, claimed)
    end
  end

  test "upload/4 reports an S3 failure as a bad request" do
    path = write_temp("l1a.pdf", "PDF bytes")

    with_mock ExAws, [:passthrough],
      request: fn operation, _options ->
        if operation.http_method == :head,
          do: {:error, {:http_error, 404, %{}}},
          else: {:error, :econnrefused}
      end do
      assert {:error, {:bad_request, message}} = DocumentUploader.upload("l1a.pdf", path, 7)
      assert message =~ "Failed to upload to S3"
    end
  end

  test "upload/4 reports an unreadable file rather than crashing" do
    assert {:error, {:bad_request, message}} =
             DocumentUploader.upload("l1a.pdf", "/nonexistent/l1a.pdf", 7)

    assert message =~ "Could not read uploaded file"
  end

  # A deployment with no bucket must say so, rather than surfacing an ExAws credentials error
  # that reads like the operator got their AWS keys wrong.
  test "upload/4 explains an unconfigured bucket before touching S3" do
    original = Application.fetch_env!(:cadet, :rag_documents)
    Application.put_env(:cadet, :rag_documents, Keyword.delete(original, :bucket))
    on_exit(fn -> Application.put_env(:cadet, :rag_documents, original) end)

    path = write_temp("l1a.pdf", "PDF bytes")

    with_mock ExAws, [:passthrough], request: fn _operation, _options -> {:ok, %{}} end do
      assert {:error, {:bad_request, message}} = DocumentUploader.upload("l1a.pdf", path, 7)
      assert message =~ "RAG_DOCUMENTS_BUCKET is unset"
      refute called(ExAws.request(:_, :_))
    end
  end

  test "upload/4 accepts every extension it advertises" do
    for ext <- DocumentUploader.accepted_extensions() do
      path = write_temp("l1a#{ext}", "bytes")

      with_mock ExAws, [:passthrough],
        request: fn operation, _options ->
          if operation.http_method == :head,
            do: {:error, {:http_error, 404, %{}}},
            else: {:ok, %{}}
        end do
        assert {:ok, %{s3_key: s3_key, media_type: media_type}} =
                 DocumentUploader.upload("l1a#{ext}", path, 7)

        assert s3_key == "course-7/l1a#{ext}"
        refute media_type == "application/octet-stream"
      end
    end
  end

  test "upload/4 is case-insensitive about the extension" do
    path = write_temp("L1A.PDF", "bytes")

    with_mock ExAws, [:passthrough],
      request: fn operation, _options ->
        if operation.http_method == :head, do: {:error, {:http_error, 404, %{}}}, else: {:ok, %{}}
      end do
      assert {:ok, %{s3_key: "course-7/l1a.pdf", media_type: "application/pdf"}} =
               DocumentUploader.upload("L1A.PDF", path, 7)
    end
  end

  describe "rename/3" do
    test "copies to the new key and removes the old object" do
      parent = self()

      with_mock ExAws, [:passthrough],
        request: fn operation, _options ->
          send(parent, {:request, operation.http_method, operation.path})

          if operation.http_method == :head,
            do: {:error, {:http_error, 404, %{}}},
            else: {:ok, %{}}
        end do
        assert {:ok, %{s3_key: "course-1/lecture-1a.pdf", media_type: "application/pdf"}} =
                 DocumentUploader.rename("course-1/old.pdf", "Lecture 1A.pdf", 1)

        assert_receive {:request, :put, "course-1/lecture-1a.pdf"}
        assert_receive {:request, :delete, "course-1/old.pdf"}
      end
    end

    test "reports a failed copy without deleting the original" do
      parent = self()

      with_mock ExAws, [:passthrough],
        request: fn operation, _options ->
          send(parent, {:request, operation.http_method})

          case operation.http_method do
            :head -> {:error, {:http_error, 404, %{}}}
            :put -> {:error, :econnrefused}
            _ -> {:ok, %{}}
          end
        end do
        capture_log(fn ->
          assert {:error, {:bad_request, "Failed to rename document in S3"}} =
                   DocumentUploader.rename("course-1/old.pdf", "new.pdf", 1)
        end)

        refute_receive {:request, :delete}
      end
    end

    test "rejects an unsupported extension" do
      assert {:error, {:bad_request, message}} =
               DocumentUploader.rename("course-1/old.pdf", "new.exe", 1)

      assert message =~ ".exe files are not supported"
      assert message =~ "Accepted file types are"
    end
  end

  describe "restore_rename/2" do
    test "copies back and removes the object the failed rename created" do
      parent = self()

      with_mock ExAws, [:passthrough],
        request: fn operation, _options ->
          send(parent, {:request, operation.http_method, operation.path})
          {:ok, %{}}
        end do
        assert :ok = DocumentUploader.restore_rename("course-1/new.pdf", "course-1/old.pdf")

        assert_receive {:request, :put, "course-1/old.pdf"}
        assert_receive {:request, :delete, "course-1/new.pdf"}
      end
    end

    test "reports a failed restore" do
      with_mock ExAws, [:passthrough],
        request: fn _operation, _options -> {:error, :timeout} end do
        capture_log(fn ->
          assert {:error, {:bad_request, "Failed to restore document in S3"}} =
                   DocumentUploader.restore_rename("course-1/new.pdf", "course-1/old.pdf")
        end)
      end
    end
  end

  describe "delete/1" do
    test "removes the object" do
      parent = self()

      with_mock ExAws, [:passthrough],
        request: fn operation, _options ->
          send(parent, {:request, operation.http_method, operation.path})
          {:ok, %{}}
        end do
        assert :ok = DocumentUploader.delete("course-1/l1a.pdf")
        assert_receive {:request, :delete, "course-1/l1a.pdf"}
      end
    end

    # The row is already gone by this point, so a failed delete leaks an object but must not be
    # reported as a failed deletion to the admin.
    test "reports success even when S3 refuses" do
      with_mock ExAws, [:passthrough],
        request: fn _operation, _options -> {:error, :timeout} end do
        log = capture_log(fn -> assert :ok = DocumentUploader.delete("course-1/l1a.pdf") end)
        assert log =~ "Failed to delete pixelbot document course-1/l1a.pdf"
      end
    end
  end

  defp write_temp(filename, contents) do
    path = Path.join(System.tmp_dir!(), "#{System.unique_integer([:positive])}-#{filename}")
    File.write!(path, contents)
    on_exit(fn -> File.rm(path) end)
    path
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
