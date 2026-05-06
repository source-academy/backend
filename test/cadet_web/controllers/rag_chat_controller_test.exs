defmodule CadetWeb.RagChatControllerTest do
  use CadetWeb.ConnCase
  use ExVCR.Mock, adapter: ExVCR.Adapter.Hackney

  alias Cadet.Courses.Course
  alias Cadet.Repo

  import Ecto.Changeset

  @moduletag :serial

  @rag_tag [%{"chat_type" => "rag"}]

  setup_all do
    HTTPoison.start()
  end

  defp setup_rag_course(conn) do
    user = conn.assigns.current_user
    course = Repo.get!(Course, user.latest_viewed_course_id)

    Repo.update!(
      change(course, %{
        pixelbot_routing_prompt: "Route: %DOCUMENT_MAP%",
        pixelbot_answer_prompt: "Answer the question."
      })
    )

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
    test "course with empty pixelbot prompts returns 422", %{conn: conn} do
      user = conn.assigns.current_user
      course = Repo.get!(Course, user.latest_viewed_course_id)

      # Explicitly set prompts to empty strings
      Repo.update!(
        change(course, %{
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
    test "no RAG conversation returns 404", %{conn: conn} do
      user = conn.assigns.current_user
      course = Repo.get!(Course, user.latest_viewed_course_id)

      Repo.update!(
        change(course, %{
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
  end
end
