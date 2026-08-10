defmodule Cadet.Chatbot.DocumentStoreTest do
  use ExUnit.Case

  import ExUnit.CaptureLog
  import Mock

  alias Cadet.Chatbot.DocumentStore

  @moduletag :serial

  defp document(overrides \\ %{}) do
    Map.merge(
      %{"id" => "l1a", "title" => "L1A", "s3_key" => "course-1/l1a.pdf"},
      overrides
    )
  end

  defp with_s3(response_fn, fun) do
    with_mock ExAws, [:passthrough], request: response_fn do
      fun.()
    end
  end

  describe "fetch_document_binary/1" do
    test "returns the object body" do
      with_s3(fn _op, _opts -> {:ok, %{body: "PDF bytes"}} end, fn ->
        assert {:ok, "PDF bytes"} = DocumentStore.fetch_document_binary(document())
      end)
    end

    test "passes the failure reason through" do
      with_s3(fn _op, _opts -> {:error, {:http_error, 404, %{}}} end, fn ->
        capture_log(fn ->
          assert {:error, {:http_error, 404, %{}}} =
                   DocumentStore.fetch_document_binary(document())
        end)
      end)
    end
  end

  describe "encode_document_base64/1" do
    test "base64-encodes the object body" do
      with_s3(fn _op, _opts -> {:ok, %{body: "PDF bytes"}} end, fn ->
        assert {:ok, encoded} = DocumentStore.encode_document_base64(document())
        assert Base.decode64!(encoded) == "PDF bytes"
      end)
    end

    test "passes a fetch failure through without encoding" do
      with_s3(fn _op, _opts -> {:error, :timeout} end, fn ->
        capture_log(fn ->
          assert {:error, :timeout} = DocumentStore.encode_document_base64(document())
        end)
      end)
    end
  end

  describe "fetch_and_encode_documents/1" do
    test "returns one attachment per document" do
      with_s3(fn _op, _opts -> {:ok, %{body: "PDF bytes"}} end, fn ->
        assert [first, second] =
                 DocumentStore.fetch_and_encode_documents([
                   document(),
                   document(%{"id" => "l1b", "title" => "L1B", "s3_key" => "course-1/l1b.pdf"})
                 ])

        assert first.title == "L1A"
        assert second.title == "L1B"
        assert Base.decode64!(first.base64) == "PDF bytes"
      end)
    end

    test "returns an empty list for no documents" do
      assert DocumentStore.fetch_and_encode_documents([]) == []
    end

    # One unreadable object must not sink the whole answer: the remaining documents are still
    # worth attaching, and the pipeline only falls back when every fetch fails.
    test "skips the documents that could not be fetched" do
      with_mock ExAws, [:passthrough],
        request: fn operation, _opts ->
          if operation.path =~ "missing", do: {:error, :not_found}, else: {:ok, %{body: "bytes"}}
        end do
        parent = self()

        capture_log(fn ->
          send(
            parent,
            {:attachments,
             DocumentStore.fetch_and_encode_documents([
               document(),
               document(%{"id" => "gone", "s3_key" => "course-1/missing.pdf"})
             ])}
          )
        end)

        assert_receive {:attachments, [%{title: "L1A"}]}
      end
    end

    # The stored media type is authoritative because the S3 key is a slug of the title and may
    # carry an extension that no longer matches the file the admin uploaded.
    test "prefers the document's stored media type over the key's extension" do
      with_s3(fn _op, _opts -> {:ok, %{body: "bytes"}} end, fn ->
        assert [%{media_type: "text/x-tex"}] =
                 DocumentStore.fetch_and_encode_documents([
                   document(%{"media_type" => "text/x-tex", "s3_key" => "course-1/notes.pdf"})
                 ])
      end)
    end

    test "derives the media type from the extension for rows saved before it was stored" do
      cases = [
        {"course-1/l1a.pdf", "application/pdf"},
        {"course-1/l1a.pptx",
         "application/vnd.openxmlformats-officedocument.presentationml.presentation"},
        {"course-1/l1a.docx",
         "application/vnd.openxmlformats-officedocument.wordprocessingml.document"},
        {"course-1/l1a.tex", "text/x-tex"},
        {"course-1/l1a.xml", "application/xml"},
        {"course-1/l1a.zip", "application/octet-stream"},
        {"course-1/l1a", "application/octet-stream"}
      ]

      with_s3(fn _op, _opts -> {:ok, %{body: "bytes"}} end, fn ->
        for {s3_key, expected} <- cases do
          assert [%{media_type: ^expected}] =
                   DocumentStore.fetch_and_encode_documents([
                     document(%{"s3_key" => s3_key, "media_type" => nil})
                   ])
        end
      end)
    end
  end
end
