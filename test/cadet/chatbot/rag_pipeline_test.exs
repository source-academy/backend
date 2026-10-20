defmodule Cadet.Chatbot.RagPipelineTest do
  use Cadet.DataCase
  use ExVCR.Mock, adapter: ExVCR.Adapter.Hackney

  import ExUnit.CaptureLog
  import Mock

  alias Cadet.Chatbot.{CourseDocuments, RagPipeline}

  @moduletag :serial

  @answer_prompt "You are a helpful tutor."

  setup_all do
    HTTPoison.start()
    :ok
  end

  defp opts_for(course_id, overrides \\ []) do
    Keyword.merge(
      [
        routing_prompt: "Select relevant docs from: %DOCUMENT_MAP%",
        answer_prompt: @answer_prompt,
        model: "gpt-4o",
        course_id: course_id,
        llm_config: %OpenAI.Config{api_key: "sk-course-key"}
      ],
      overrides
    )
  end

  defp course_with_document(title \\ "L1A", filename \\ "l1a.pdf") do
    course = insert(:course)
    {:ok, category} = CourseDocuments.create_category(course.id, "lecture")

    {:ok, [document]} =
      CourseDocuments.create_documents(course.id, [
        %{
          category_id: category.id,
          title: title,
          s3_key: "course-#{course.id}/#{filename}",
          filename: filename,
          media_type: "application/pdf"
        }
      ])

    {course, document}
  end

  defp routing_response(content) do
    {:ok, %{choices: [%{"message" => %{"content" => content}}]}}
  end

  describe "process_rag_query/2" do
    test "returns :no_docs when the course has no documents" do
      course = insert(:course)

      assert {:no_docs, @answer_prompt} =
               RagPipeline.process_rag_query("What is recursion?", opts_for(course.id))
    end

    # The routing call is skipped entirely for an empty map, so no HTTP mock is needed above and
    # none of the fallbacks below can be reached by accident.
    test "does not call the routing LLM when the map is empty" do
      course = insert(:course)

      with_mock OpenAI, [:passthrough],
        chat_completion: fn _opts, _config -> routing_response("[]") end do
        RagPipeline.process_rag_query("What is recursion?", opts_for(course.id))
        refute called(OpenAI.chat_completion(:_, :_))
      end
    end

    test "attaches the documents the routing LLM selected" do
      {course, document} = course_with_document()

      with_mock OpenAI, [:passthrough],
        chat_completion: fn _opts, _config -> routing_response(~s(["#{document.doc_key}"])) end do
        with_mock ExAws, [:passthrough], request: fn _op, _opts -> {:ok, %{body: "PDF"}} end do
          assert {:rag, @answer_prompt, [attachment]} =
                   RagPipeline.process_rag_query("What is recursion?", opts_for(course.id))

          assert attachment.title == "L1A"
          assert attachment.media_type == "application/pdf"
          assert Base.decode64!(attachment.base64) == "PDF"
        end
      end
    end

    # Models wrap the array in prose often enough that the pipeline digs the JSON out rather than
    # discarding an otherwise good routing decision.
    test "extracts the id array from a response wrapped in prose" do
      {course, document} = course_with_document()

      with_mock OpenAI, [:passthrough],
        chat_completion: fn _opts, _config ->
          routing_response(
            "Sure! The relevant document is:\n[\"#{document.doc_key}\"]\nHope that helps."
          )
        end do
        with_mock ExAws, [:passthrough], request: fn _op, _opts -> {:ok, %{body: "PDF"}} end do
          assert {:rag, @answer_prompt, [_attachment]} =
                   capture_log_result(fn ->
                     RagPipeline.process_rag_query("What is recursion?", opts_for(course.id))
                   end)
        end
      end
    end

    test "falls back when the routing LLM selects nothing" do
      {course, _document} = course_with_document()

      with_mock OpenAI, [:passthrough],
        chat_completion: fn _opts, _config -> routing_response("[]") end do
        assert {:no_docs, @answer_prompt} =
                 RagPipeline.process_rag_query("What is the weather?", opts_for(course.id))
      end
    end

    # Routing is scoped to this course, so an id from another course's map cannot pull that
    # course's documents into the answer.
    test "falls back when the selected ids match nothing in this course" do
      {course, _document} = course_with_document()
      {_other_course, other_document} = course_with_document("Other", "other.pdf")

      with_mock OpenAI, [:passthrough],
        chat_completion: fn _opts, _config ->
          routing_response(~s(["#{other_document.doc_key}"]))
        end do
        assert {:no_docs, @answer_prompt} =
                 capture_log_result(fn ->
                   RagPipeline.process_rag_query("What is recursion?", opts_for(course.id))
                 end)
      end
    end

    test "falls back when every document fetch fails" do
      {course, document} = course_with_document()

      with_mock OpenAI, [:passthrough],
        chat_completion: fn _opts, _config -> routing_response(~s(["#{document.doc_key}"])) end do
        with_mock ExAws, [:passthrough], request: fn _op, _opts -> {:error, :timeout} end do
          assert {:no_docs, @answer_prompt} =
                   capture_log_result(fn ->
                     RagPipeline.process_rag_query("What is recursion?", opts_for(course.id))
                   end)
        end
      end
    end

    test "falls back when the routing response is not JSON at all" do
      {course, _document} = course_with_document()

      with_mock OpenAI, [:passthrough],
        chat_completion: fn _opts, _config ->
          routing_response("I don't know which document to use.")
        end do
        assert {:no_docs, @answer_prompt} =
                 capture_log_result(fn ->
                   RagPipeline.process_rag_query("What is recursion?", opts_for(course.id))
                 end)
      end
    end

    test "falls back when the extracted array is malformed" do
      {course, _document} = course_with_document()

      with_mock OpenAI, [:passthrough],
        chat_completion: fn _opts, _config -> routing_response("Here: [\"l1a\", ] done") end do
        assert {:no_docs, @answer_prompt} =
                 capture_log_result(fn ->
                   RagPipeline.process_rag_query("What is recursion?", opts_for(course.id))
                 end)
      end
    end

    test "falls back when the routing response has no choices" do
      {course, _document} = course_with_document()

      with_mock OpenAI, [:passthrough],
        chat_completion: fn _opts, _config -> {:ok, %{choices: []}} end do
        assert {:no_docs, @answer_prompt} =
                 capture_log_result(fn ->
                   RagPipeline.process_rag_query("What is recursion?", opts_for(course.id))
                 end)
      end
    end

    test "falls back when the routing call itself fails" do
      {course, _document} = course_with_document()

      with_mock OpenAI, [:passthrough],
        chat_completion: fn _opts, _config -> {:error, %{"error" => "rate limited"}} end do
        assert {:no_docs, @answer_prompt} =
                 capture_log_result(fn ->
                   RagPipeline.process_rag_query("What is recursion?", opts_for(course.id))
                 end)
      end
    end

    # Without the placeholder the routing prompt would be sent with no document map in it, and the
    # model would be asked to pick from a list it was never shown.
    test "falls back when the routing prompt has no document map placeholder" do
      {course, _document} = course_with_document()

      with_mock OpenAI, [:passthrough],
        chat_completion: fn _opts, _config -> routing_response("[]") end do
        assert {:no_docs, @answer_prompt} =
                 capture_log_result(fn ->
                   RagPipeline.process_rag_query(
                     "What is recursion?",
                     opts_for(course.id, routing_prompt: "Pick a document.")
                   )
                 end)

        refute called(OpenAI.chat_completion(:_, :_))
      end
    end
  end

  # Runs fun/0 with the logs swallowed and returns its value; the fallbacks all log at :error or
  # :warning, which would otherwise bury the test output.
  defp capture_log_result(fun) do
    parent = self()
    capture_log(fn -> send(parent, {:result, fun.()}) end)
    assert_receive {:result, result}
    result
  end
end
