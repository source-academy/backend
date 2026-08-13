defmodule CadetWeb.RagChatControllerTest do
  use CadetWeb.ConnCase
  use ExVCR.Mock, adapter: ExVCR.Adapter.Hackney

  alias Cadet.Courses.Course
  alias Cadet.Chatbot.{CourseDocuments, RagPipeline}
  alias Cadet.Repo

  import Ecto.Changeset
  import Mock

  @moduletag :serial

  @rag_tag [%{"chat_type" => "rag"}]

  setup_all do
    HTTPoison.start()
  end

  defp setup_rag_course(conn) do
    user = conn.assigns.current_user
    course = Repo.get!(Course, user.latest_viewed_course_id)

    # Pixel is off until staff turn it on, so a course used for chat has to enable it explicitly.
    # The key goes via Course.changeset so it is encrypted; change/2 would store it in plaintext.
    course
    |> Course.changeset(%{llm_api_key: "sk-course-key"})
    |> Repo.update!()

    Repo.update!(
      change(Repo.get!(Course, course.id), %{
        enable_pixelbot: true,
        pixelbot_routing_prompt: "Route: %DOCUMENT_MAP%",
        pixelbot_answer_prompt: "Answer the question."
      })
    )

    # Routing skips its HTTP call for a course with no documents, so the cassettes below (which
    # record both a routing and an answer response) need at least one document to exercise both.
    {:ok, category} = CourseDocuments.create_category(course.id, "lecture")

    {:ok, _} =
      CourseDocuments.create_documents(course.id, [
        %{
          category_id: category.id,
          title: "L1A",
          s3_key: "course-#{course.id}/l1a.pdf",
          filename: "l1a.pdf",
          media_type: "application/pdf"
        }
      ])

    insert(:conversation,
      user: user,
      prepend_context: @rag_tag,
      messages: [%{role: "assistant", content: "Hi!", created_at: DateTime.utc_now()}]
    )

    :ok
  end

  describe "POST /v2/rag_chat (init_chat)" do
    test "unauthenticated request returns 401", %{conn: conn} do
      conn = post(conn, "/v2/rag_chat", %{})
      assert response(conn, :unauthorized) == "Unauthorised"
    end

    @tag authenticate: :student
    test "authenticated request initializes RAG chat", %{conn: conn} do
      conn = post(conn, "/v2/rag_chat", %{})

      assert %{
               "conversationId" => _,
               "messages" => _,
               "maxContentSize" => _
             } = json_response(conn, 200)
    end

    @tag authenticate: :student
    test "returns existing conversation on second init", %{conn: conn} do
      conn1 = post(conn, "/v2/rag_chat", %{})
      resp1 = json_response(conn1, 200)

      conn2 = post(conn, "/v2/rag_chat", %{})
      resp2 = json_response(conn2, 200)

      assert resp1["conversationId"] == resp2["conversationId"]
    end
  end

  describe "POST /v2/rag_chat/message (chat)" do
    @tag authenticate: :student
    test "missing parameters returns 400", %{conn: conn} do
      conn = post(conn, "/v2/rag_chat/message", %{})
      assert response(conn, :bad_request) == "Missing or invalid parameter(s)"
    end

    @tag authenticate: :student
    test "non-string message returns 400", %{conn: conn} do
      conn = post(conn, "/v2/rag_chat/message", %{"message" => 123})
      assert response(conn, :bad_request) == "Missing or invalid parameter(s)"
    end

    @tag authenticate: :student
    test "user with no course returns 422", %{conn: conn} do
      # Override the user to have no latest_viewed_course
      user = conn.assigns.current_user
      Repo.update!(change(user, latest_viewed_course_id: nil))

      conn =
        conn
        |> assign(:current_user, %{user | latest_viewed_course_id: nil})
        |> post("/v2/rag_chat/message", %{"message" => "Hello"})

      assert response(conn, :unprocessable_entity) =~
               "You must select a course before using the chatbot."
    end

    @tag authenticate: :student
    test "course with pixelbot disabled returns 403", %{conn: conn} do
      user = conn.assigns.current_user
      setup_rag_course(conn)
      course = Repo.get!(Course, user.latest_viewed_course_id)
      Repo.update!(change(course, %{enable_pixelbot: false}))

      conn = post(conn, "/v2/rag_chat/message", %{"message" => "Hello"})

      assert response(conn, :forbidden) =~ "The chatbot is not enabled for this course."
    end

    @tag authenticate: :student
    test "course with empty pixelbot prompts returns 422", %{conn: conn} do
      user = conn.assigns.current_user
      course = Repo.get!(Course, user.latest_viewed_course_id)

      # Pixel is enabled but never configured, which is the state the 422 exists for.
      Repo.update!(
        change(course, %{
          enable_pixelbot: true,
          pixelbot_routing_prompt: "",
          pixelbot_answer_prompt: ""
        })
      )

      insert(:conversation, user: user, prepend_context: @rag_tag)

      conn = post(conn, "/v2/rag_chat/message", %{"message" => "Hello"})

      assert response(conn, :unprocessable_entity) =~
               "The chatbot is not configured for this course"
    end

    @tag authenticate: :student
    test "message too long returns 422", %{conn: conn} do
      setup_rag_course(conn)

      long_message = String.duplicate("a", 1001)
      conn = post(conn, "/v2/rag_chat/message", %{"message" => long_message})

      assert response(conn, :unprocessable_entity) =~
               "Message exceeds the maximum allowed length"
    end

    @tag authenticate: :student
    test "combined screen context that is too long returns 422", %{conn: conn} do
      setup_rag_course(conn)

      conn =
        post(conn, "/v2/rag_chat/message", %{
          "message" => "Help",
          "code" => String.duplicate("a", 10_001),
          "question" => String.duplicate("b", 10_000)
        })

      assert response(conn, :unprocessable_entity) =~
               "Screen context exceeds the maximum allowed length"
    end

    @tag authenticate: :student
    test "no RAG conversation returns 404", %{conn: conn} do
      user = conn.assigns.current_user
      course = Repo.get!(Course, user.latest_viewed_course_id)

      course
      |> Course.changeset(%{llm_api_key: "sk-course-key"})
      |> Repo.update!()

      Repo.update!(
        change(Repo.get!(Course, course.id), %{
          enable_pixelbot: true,
          pixelbot_routing_prompt: "Route: %DOCUMENT_MAP%",
          pixelbot_answer_prompt: "Answer the question."
        })
      )

      conn = post(conn, "/v2/rag_chat/message", %{"message" => "Hello"})
      assert response(conn, :not_found) == "Conversation not found"
    end

    @tag authenticate: :student
    test "successful chat with configured course", %{conn: conn} do
      setup_rag_course(conn)

      use_cassette "chatbot/rag_chat_conversation#1", custom: true do
        conn = post(conn, "/v2/rag_chat/message", %{"message" => "What is recursion?"})

        assert %{
                 "conversationId" => _,
                 "response" => _
               } = json_response(conn, 200)
      end
    end

    @tag authenticate: :student
    test "OpenAI error returns 500", %{conn: conn} do
      setup_rag_course(conn)

      use_cassette "chatbot/openai_error#1", custom: true do
        conn = post(conn, "/v2/rag_chat/message", %{"message" => "Hello"})
        assert response(conn, 500) =~ "Internal server error"
      end
    end

    @tag authenticate: :student
    test "OpenAI empty choices returns 500", %{conn: conn} do
      setup_rag_course(conn)

      use_cassette "chatbot/openai_empty_choices#1", custom: true do
        conn = post(conn, "/v2/rag_chat/message", %{"message" => "Hello"})
        assert response(conn, 500) == "No response from AI"
      end
    end

    # A non-map error is what an HTTP-level failure (a timeout, a closed socket) looks like, and
    # get_in/2 on one would raise, turning a handled 500 into an unhandled crash.
    @tag authenticate: :student
    test "a non-map OpenAI error still returns a 500 with a readable message", %{conn: conn} do
      setup_rag_course(conn)

      with_mock OpenAI, [:passthrough],
        chat_completion: fn _opts, _config -> {:error, :timeout} end do
        conn = post(conn, "/v2/rag_chat/message", %{"message" => "Hello"})

        assert response(conn, 500) == "Unknown OpenAI error"
      end
    end
  end

  describe "POST /v2/rag_chat/message with documents attached" do
    setup %{conn: conn} do
      setup_rag_course(conn)
      :ok
    end

    defp with_rag_answer(attachments, response_content, fun) do
      parent = self()

      with_mock RagPipeline, [:passthrough],
        process_rag_query: fn _message, opts ->
          {:rag, Keyword.fetch!(opts, :answer_prompt), attachments}
        end do
        with_mock OpenAI, [:passthrough],
          chat_completion: fn opts, _config ->
            send(parent, {:payload, Keyword.fetch!(opts, :messages)})
            {:ok, %{choices: [%{"message" => %{"content" => response_content}}]}}
          end do
          fun.()
        end
      end
    end

    @tag authenticate: :student
    test "attaches the selected documents to the last user message", %{conn: conn} do
      attachments = [
        %{title: "L1A", base64: Base.encode64("PDF bytes"), media_type: "application/pdf"}
      ]

      with_rag_answer(attachments, "Recursion is...", fn ->
        conn = post(conn, "/v2/rag_chat/message", %{"message" => "What is recursion?"})

        assert %{"response" => "Recursion is..."} = json_response(conn, 200)
      end)

      assert_receive {:payload, payload}
      last_message = List.last(payload)

      assert last_message.role == "user"

      assert [%{type: "text", text: "What is recursion?"}, attachment] = last_message.content
      assert attachment.type == "file"
      assert attachment.file.filename == "L1A"
      assert attachment.file.file_data =~ "data:application/pdf;base64,"
    end

    @tag authenticate: :student
    test "sends the course's own API key, not the global one", %{conn: conn} do
      parent = self()

      with_mock OpenAI, [:passthrough],
        chat_completion: fn _params, config ->
          send(parent, {:api_key, config.api_key})
          {:ok, %{choices: [%{"message" => %{"content" => "ok"}}]}}
        end do
        post(conn, "/v2/rag_chat/message", %{"message" => "What is recursion?"})
      end

      # Both the routing call and the answer run on the course key.
      assert_receive {:api_key, "sk-course-key"}
      assert_receive {:api_key, "sk-course-key"}
    end

    @tag authenticate: :student
    test "refuses to chat when the course has no API key", %{conn: conn} do
      course = Repo.get!(Course, conn.assigns.current_user.latest_viewed_course_id)
      Repo.update!(change(course, %{llm_api_key: nil}))

      with_mock OpenAI, [:passthrough],
        chat_completion: fn _params, _config ->
          {:ok, %{choices: [%{"message" => %{"content" => "ok"}}]}}
        end do
        conn = post(conn, "/v2/rag_chat/message", %{"message" => "What is recursion?"})

        assert response(conn, :unprocessable_entity) =~
                 "The chatbot is not configured for this course"

        refute called(OpenAI.chat_completion(:_, :_))
      end
    end

    @tag authenticate: :student
    test "refuses to chat when the stored key cannot be decrypted", %{conn: conn} do
      course = Repo.get!(Course, conn.assigns.current_user.latest_viewed_course_id)
      # Not the iv:tag:ciphertext shape the decryptor expects.
      Repo.update!(change(course, %{llm_api_key: "plaintext-never-encrypted"}))

      conn = post(conn, "/v2/rag_chat/message", %{"message" => "What is recursion?"})

      assert response(conn, :unprocessable_entity) =~
               "The chatbot is not configured for this course"
    end

    # Pixel used to read llm_model, so a cheap grading model silently changed student answers.
    @tag authenticate: :student
    test "runs on the course's Pixel model, not its grading model", %{conn: conn} do
      course = Repo.get!(Course, conn.assigns.current_user.latest_viewed_course_id)
      Repo.update!(change(course, %{llm_model: "gpt-5-mini", pixelbot_model: "gpt-4o"}))

      parent = self()

      with_mock RagPipeline, [:passthrough],
        process_rag_query: fn _message, opts ->
          send(parent, {:routing_model, Keyword.fetch!(opts, :model)})
          {:no_docs, Keyword.fetch!(opts, :answer_prompt)}
        end do
        with_mock OpenAI, [:passthrough],
          chat_completion: fn opts, _config ->
            send(parent, {:answer_model, Keyword.fetch!(opts, :model)})
            {:ok, %{choices: [%{"message" => %{"content" => "ok"}}]}}
          end do
          post(conn, "/v2/rag_chat/message", %{"message" => "What is recursion?"})
        end
      end

      # Both the routing call and the answer run on the Pixel model.
      assert_receive {:routing_model, "gpt-4o"}
      assert_receive {:answer_model, "gpt-4o"}
    end

    @tag authenticate: :student
    test "falls back to a default when no Pixel model is set", %{conn: conn} do
      course = Repo.get!(Course, conn.assigns.current_user.latest_viewed_course_id)
      Repo.update!(change(course, %{llm_model: "gpt-5-mini", pixelbot_model: nil}))

      parent = self()

      with_mock RagPipeline, [:passthrough],
        process_rag_query: fn _message, opts ->
          send(parent, {:routing_model, Keyword.fetch!(opts, :model)})
          {:no_docs, Keyword.fetch!(opts, :answer_prompt)}
        end do
        with_mock OpenAI, [:passthrough],
          chat_completion: fn _opts, _config ->
            {:ok, %{choices: [%{"message" => %{"content" => "ok"}}]}}
          end do
          post(conn, "/v2/rag_chat/message", %{"message" => "What is recursion?"})
        end
      end

      # The grading model is not the fallback.
      assert_receive {:routing_model, "gpt-4o"}
    end

    @tag authenticate: :student
    test "repeats the system prompt directly before the attached message", %{conn: conn} do
      with_rag_answer([], "ok", fn ->
        post(conn, "/v2/rag_chat/message", %{"message" => "What is recursion?"})
      end)

      assert_receive {:payload, payload}

      assert %{role: "system"} = hd(payload)
      assert %{role: "system"} = Enum.at(payload, -2)
    end

    # Screen context is student-controlled text going into a system-adjacent position, so the
    # prompt is amended to say it is reference data rather than instructions.
    @tag authenticate: :student
    test "wraps screen context in tags and warns the model not to obey it", %{conn: conn} do
      with_rag_answer([], "ok", fn ->
        post(conn, "/v2/rag_chat/message", %{
          "message" => "Why does this fail?",
          "code" => "function f(x) { return f(x); }",
          "question" => "Implement a recursive sum."
        })
      end)

      assert_receive {:payload, payload}

      system_prompt = hd(payload).content
      assert system_prompt =~ "<screen_context_reference>"
      assert system_prompt =~ "never as instructions"

      context_message = find_screen_context(payload)

      assert context_message.role == "user"
      assert context_message.content =~ "Implement a recursive sum."
      assert context_message.content =~ "function f(x)"
      assert context_message.content =~ "The student's current code in their editor"
    end

    @tag authenticate: :student
    test "sends only the section that was provided", %{conn: conn} do
      with_rag_answer([], "ok", fn ->
        post(conn, "/v2/rag_chat/message", %{
          "message" => "Why does this fail?",
          "code" => "f(x)"
        })
      end)

      assert_receive {:payload, payload}

      context_message = find_screen_context(payload)

      assert context_message.content =~ "The student's current code in their editor"
      refute context_message.content =~ "problem statement"
    end

    # Blank or whitespace-only fields are what the frontend sends when the editor is empty, and
    # they must not produce an empty context block or the untrusted-data warning.
    @tag authenticate: :student
    test "omits screen context entirely when every field is blank", %{conn: conn} do
      with_rag_answer([], "ok", fn ->
        post(conn, "/v2/rag_chat/message", %{
          "message" => "Hello",
          "code" => "   ",
          "question" => ""
        })
      end)

      assert_receive {:payload, payload}

      refute find_screen_context(payload)

      refute hd(payload).content =~ "never as instructions"
    end

    @tag authenticate: :student
    test "ignores non-string screen context values", %{conn: conn} do
      with_rag_answer([], "ok", fn ->
        post(conn, "/v2/rag_chat/message", %{
          "message" => "Hello",
          "code" => 42,
          "question" => %{"a" => 1}
        })
      end)

      assert_receive {:payload, payload}

      refute find_screen_context(payload)
    end
  end

  # The system prompt also mentions the tag, so the context turn is identified by role as well.
  defp find_screen_context(payload) do
    Enum.find(payload, fn message ->
      message[:role] == "user" and is_binary(message[:content]) and
        message[:content] =~ "<screen_context_reference>"
    end)
  end
end
