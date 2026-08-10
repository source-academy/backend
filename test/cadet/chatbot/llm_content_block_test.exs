defmodule Cadet.Chatbot.LlmContentBlockTest do
  use ExUnit.Case, async: true

  alias Cadet.Chatbot.LlmContentBlock

  test "build/3 emits valid UTF-8 text documents as text blocks" do
    base64 = Base.encode64("hello")

    assert %{type: "text", text: "Document: notes.tex\n\nhello"} =
             LlmContentBlock.build("notes.tex", base64, "text/x-tex")
  end

  test "build/3 falls back to a file block for malformed base64 text documents" do
    assert %{type: "file", file: %{file_data: "data:text/x-tex;base64,%%%"}} =
             LlmContentBlock.build("notes.tex", "%%%", "text/x-tex")
  end

  test "build/3 falls back to a file block for non-UTF-8 text documents" do
    base64 = Base.encode64(<<255>>)

    assert %{type: "file"} = LlmContentBlock.build("notes.tex", base64, "text/x-tex")
  end

  # A PDF or Office document is binary no matter what, so it is never decoded to check: it goes
  # as a file block with the data URI the API expects.
  test "build/3 sends binary formats as file blocks without decoding them" do
    base64 = Base.encode64("PDF bytes")

    for media_type <- [
          "application/pdf",
          "application/vnd.openxmlformats-officedocument.presentationml.presentation",
          "application/vnd.openxmlformats-officedocument.wordprocessingml.document",
          "application/octet-stream"
        ] do
      assert %{type: "file", file: %{filename: "l1a", file_data: file_data}} =
               LlmContentBlock.build("l1a", base64, media_type)

      assert file_data == "data:#{media_type};base64,#{base64}"
    end
  end

  test "build/3 sends the other text formats as text when they decode cleanly" do
    base64 = Base.encode64("<root/>")

    for media_type <- ["application/xml", "text/xml"] do
      assert %{type: "text", text: "Document: feed.xml\n\n<root/>"} =
               LlmContentBlock.build("feed.xml", base64, media_type)
    end
  end
end
