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
end
