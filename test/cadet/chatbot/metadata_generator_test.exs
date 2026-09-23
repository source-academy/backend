defmodule Cadet.Chatbot.MetadataGeneratorTest do
  use ExUnit.Case

  import ExUnit.CaptureLog
  import Mock

  alias Cadet.Chatbot.MetadataGenerator

  @moduletag :serial

  defp openai_response(content) do
    {:ok, %{choices: [%{"message" => %{"content" => content}}]}}
  end

  defp generate(response_fn) do
    with_mock OpenAI, [:passthrough], chat_completion: response_fn do
      MetadataGenerator.generate(
        "Lecture 1A.pdf",
        Base.encode64("hi"),
        "application/pdf",
        "gpt-4o",
        %OpenAI.Config{api_key: "sk-course-key"}
      )
    end
  end

  test "returns the description from a clean JSON response" do
    metadata =
      generate(fn _opts, _config ->
        openai_response(~s({"description": "Covers recursion and the substitution model."}))
      end)

    assert metadata == %{
             title: "Lecture 1A",
             description: "Covers recursion and the substitution model."
           }
  end

  test "tolerates whitespace and a fenced code block around the JSON" do
    metadata =
      generate(fn _opts, _config ->
        openai_response("""
        Here you go:

        ```json
        {"description": "Covers tail calls."}
        ```
        """)
      end)

    assert metadata.description == "Covers tail calls."
  end

  # The title always comes from the filename, never from the model: the admin is shown the
  # proposal next to the file they just picked, and a model-invented title would not match it.
  test "derives the title from the filename and ignores any the model supplies" do
    metadata =
      generate(fn _opts, _config ->
        openai_response(~s({"title": "Something Else", "description": "Covers lists."}))
      end)

    assert metadata.title == "Lecture 1A"
  end

  test "falls back to a blank description when the response is not JSON at all" do
    metadata = generate(fn _opts, _config -> openai_response("I cannot read this document.") end)

    assert metadata == %{title: "Lecture 1A", description: ""}
  end

  test "falls back to a blank description when the JSON is malformed" do
    metadata = generate(fn _opts, _config -> openai_response(~s({"description": )) end)

    assert metadata == %{title: "Lecture 1A", description: ""}
  end

  test "falls back to a blank description when the model returns an empty one" do
    metadata = generate(fn _opts, _config -> openai_response(~s({"description": ""})) end)

    assert metadata == %{title: "Lecture 1A", description: ""}
  end

  # The braces are found but what is between them is not valid JSON, so the second decode fails
  # too and there is nothing left to try.
  test "falls back to a blank description when the extracted object is malformed" do
    metadata =
      generate(fn _opts, _config -> openai_response(~s(Here you go: {"description": } done)) end)

    assert metadata == %{title: "Lecture 1A", description: ""}
  end

  test "falls back to a blank description when the JSON is not an object" do
    metadata = generate(fn _opts, _config -> openai_response(~s(["a", "b"])) end)

    assert metadata == %{title: "Lecture 1A", description: ""}
  end

  test "falls back to a blank description when there are no choices" do
    metadata = generate(fn _opts, _config -> {:ok, %{choices: []}} end)

    assert metadata == %{title: "Lecture 1A", description: ""}
  end

  # An upload that already succeeded must still reach the admin for review, so a failed metadata
  # call degrades to an empty description rather than failing the request.
  test "falls back to a blank description when the API call fails" do
    parent = self()

    log =
      capture_log(fn ->
        send(
          parent,
          {:metadata, generate(fn _opts, _config -> {:error, %{"error" => "rate limited"}} end)}
        )
      end)

    assert log =~ "Pixelbot metadata generation failed for Lecture 1A.pdf"
    assert_receive {:metadata, metadata}
    assert metadata == %{title: "Lecture 1A", description: ""}
  end

  test "sends the document as a content block on the user turn" do
    parent = self()

    with_mock OpenAI, [:passthrough],
      chat_completion: fn opts, _config ->
        send(parent, {:payload, Keyword.fetch!(opts, :messages), Keyword.fetch!(opts, :model)})
        openai_response(~s({"description": "ok"}))
      end do
      MetadataGenerator.generate(
        "notes.tex",
        Base.encode64("hello"),
        "text/x-tex",
        "gpt-5",
        %OpenAI.Config{api_key: "sk-course-key"}
      )
    end

    assert_receive {:payload, [system, user], "gpt-5"}
    assert system.role == "system"
    assert user.role == "user"

    # A .tex file is valid UTF-8, so it goes as text rather than paying the base64 overhead.
    assert [%{type: "text", text: text}] = user.content
    assert text =~ "Document: notes.tex"
    assert text =~ "hello"
  end
end
