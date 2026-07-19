defmodule CadetWeb.ChatControllerTest do
  alias Cadet.Repo
  alias CadetWeb.ChatController
  use CadetWeb.ConnCase
  use ExVCR.Mock, adapter: ExVCR.Adapter.Hackney

  @moduletag :serial

  setup_all do
    # This essentially does :application.ensure_all_started(:hackney)
    HTTPoison.start()
  end

  setup context do
    if context[:requires_setup] do
      conversation = insert(:conversation)
      {:ok, conversation_id: conversation.id}
    else
      {:ok, conversation_id: nil}
    end
  end

  test "swagger" do
    ChatController.swagger_path_chat("json")
  end

  describe "POST /chats" do
    test "unauthenticated request", %{conn: conn} do
      conn =
        post(conn, "/v2/chats", %{"json" => [%{"role" => "assistant", "content" => "Hello"}]})

      assert response(conn, :unauthorized) == "Unauthorised"
    end

    @tag authenticate: :student
    test "authenticated request initializes chat", %{conn: conn} do
      conn = post(conn, "/v2/chats", %{"languageId" => "python1"})

      assert %{
               "conversationId" => conversation_id,
               "messages" => _,
               "maxContentSize" => _
             } = json_response(conn, 200)

      assert is_integer(conversation_id)

      assert Repo.get!(Cadet.Chatbot.Conversation, conversation_id).language_id ==
               "python1"
    end

    @tag authenticate: :student
    test "rejects a language without a SICPy textbook", %{conn: conn} do
      conn = post(conn, "/v2/chats", %{"languageId" => "source1"})

      assert response(conn, :bad_request) == "Unsupported languageId"
    end

    @tag authenticate: :student
    test "rejects Python Full because it has no SICPy textbook", %{conn: conn} do
      conn = post(conn, "/v2/chats", %{"languageId" => "pythonFull"})

      assert response(conn, :bad_request) == "Unsupported languageId"
    end
  end

  describe "POST /chats/message" do
    @tag authenticate: :student
    @tag requires_setup: true
    test "Conversation belongs to another user", %{conn: conn, conversation_id: conversation_id} do
      assert conversation_id != nil

      use_cassette "chatbot/chat_conversation#1", custom: true do
        conn =
          post(conn, "/v2/chats/message", %{
            "message" => "How to implement recursion in JavaScript?",
            "section" => "SICP-1",
            "initialContext" => "Recursion is a fundamental concept in computer science."
          })

        assert response(conn, :not_found) == "Conversation not found"
      end
    end

    @tag authenticate: :student
    test "Conversation belongs to own user", %{conn: conn} do
      use_cassette "chatbot/chat_conversation#1", custom: true do
        conversation = insert(:conversation, user: conn.assigns.current_user, prepend_context: [])

        conn =
          post(conn, "/v2/chats/message", %{
            "message" => "How to implement recursion in JavaScript?",
            "section" => "SICP-1",
            "initialContext" => "Recursion is a fundamental concept in computer science."
          })

        assert json_response(conn, 200) == %{
                 "conversationId" => conversation.id,
                 "response" => "Some hardcoded test response."
               }
      end
    end

    @tag authenticate: :student
    test "uses configured vector retriever with python language internally", %{conn: conn} do
      original_config = Application.get_env(:cadet, :vector_rag)

      Application.put_env(:cadet, :vector_rag,
        enabled: true,
        top_k: 8,
        min_similarity: nil,
        retriever: CadetWeb.ChatControllerTest.FakeRetriever,
        embedding_provider: Cadet.Chatbot.OpenAIEmbeddings,
        embedding_model: "text-embedding-3-small",
        embedding_api_url: "https://api.openai.com/v1/embeddings"
      )

      on_exit(fn -> Application.put_env(:cadet, :vector_rag, original_config) end)

      use_cassette "chatbot/chat_conversation#1", custom: true do
        conversation = insert(:conversation, user: conn.assigns.current_user, prepend_context: [])

        conn =
          post(conn, "/v2/chats/message", %{
            "message" => "How do functions work?",
            "section" => "1.1.4",
            "initialContext" => "Functions bind names to reusable computations."
          })

        assert_received {:vector_rag_retrieved, query, opts}
        assert String.contains?(query, "How do functions work?")
        assert opts[:language] == "python"
        assert opts[:limit] == 8

        assert json_response(conn, 200) == %{
                 "conversationId" => conversation.id,
                 "response" => "Some hardcoded test response."
               }
      end
    end

    @tag authenticate: :student
    test "returns textbook scope message when vector RAG finds no context", %{conn: conn} do
      original_config = Application.get_env(:cadet, :vector_rag)

      Application.put_env(:cadet, :vector_rag,
        enabled: true,
        top_k: 8,
        min_similarity: 0.35,
        retriever: CadetWeb.ChatControllerTest.EmptyRetriever,
        embedding_provider: Cadet.Chatbot.OpenAIEmbeddings,
        embedding_model: "text-embedding-3-small",
        embedding_api_url: "https://api.openai.com/v1/embeddings"
      )

      on_exit(fn -> Application.put_env(:cadet, :vector_rag, original_config) end)

      conversation = insert(:conversation, user: conn.assigns.current_user, prepend_context: [])

      conn =
        post(conn, "/v2/chats/message", %{
          "message" => "what is matrix multiplication and eigenvector",
          "section" => "index",
          "initialContext" => ""
        })

      assert json_response(conn, 200) == %{
               "conversationId" => conversation.id,
               "response" =>
                 "I can only help with questions related to the Python textbook material. Please ask a textbook-related question."
             }
    end

    @tag authenticate: :student
    @tag requires_setup: true
    test "The content length is too long",
         %{conn: conn, conversation_id: conversation_id} do
      assert conversation_id != nil
      max_message_length = ChatController.max_content_length()
      message_exceed_length = String.duplicate("a", max_message_length + 1)

      conn =
        post(conn, "/v2/chats/message", %{
          "conversation_id" => conversation_id,
          "message" => "#{message_exceed_length}",
          "section" => "SICP-1",
          "initialContext" => "Recursion is a fundamental concept in computer science."
        })

      assert response(conn, :unprocessable_entity) ==
               "Message exceeds the maximum allowed length of #{max_message_length}"
    end

    @tag authenticate: :student
    test "no conversation for user with max-length message", %{conn: conn} do
      max_message_length = ChatController.max_content_length()
      message_exceed_length = String.duplicate("a", max_message_length)

      conn =
        post(conn, "/v2/chats/message", %{
          "message" => "#{message_exceed_length}",
          "section" => "SICP-1",
          "initialContext" => "Recursion is a fundamental concept in computer science."
        })

      assert response(conn, :not_found) == "Conversation not found"
    end

    @tag authenticate: :student
    test "OpenAI error returns 500", %{conn: conn} do
      use_cassette "chatbot/chat_openai_error#1", custom: true do
        insert(:conversation, user: conn.assigns.current_user, prepend_context: [])

        conn =
          post(conn, "/v2/chats/message", %{
            "message" => "Hello",
            "section" => "SICP-1",
            "initialContext" => "Some context."
          })

        assert response(conn, 500) =~ "Internal server error"
      end
    end

    @tag authenticate: :student
    test "OpenAI empty choices returns 500", %{conn: conn} do
      use_cassette "chatbot/chat_empty_choices#1", custom: true do
        insert(:conversation, user: conn.assigns.current_user, prepend_context: [])

        conn =
          post(conn, "/v2/chats/message", %{
            "message" => "Hello",
            "section" => "SICP-1",
            "initialContext" => "Some context."
          })

        assert response(conn, 500) == "No response from AI"
      end
    end

    @tag authenticate: :student
    test "missing message", %{conn: conn} do
      conn =
        post(conn, "/v2/chats/message", %{
          "section" => "SICP-1"
        })

      assert response(conn, :bad_request) == "Missing or invalid parameter(s)"
    end

    @tag authenticate: :student
    test "optional section and initialContext may be omitted", %{conn: conn} do
      conversation = insert(:conversation, user: conn.assigns.current_user, prepend_context: [])

      use_cassette "chatbot/chat_conversation#1", custom: true do
        conn =
          post(conn, "/v2/chats/message", %{
            "message" => "How do functions work?",
            "languageId" => "python4",
            "conversationId" => conversation.id
          })

        assert %{
                 "conversationId" => response_conversation_id,
                 "response" => "Some hardcoded test response."
               } = json_response(conn, 200)

        assert response_conversation_id == conversation.id
        assert Repo.reload(conversation).language_id == "python4"
      end
    end

    @tag authenticate: :student
    test "rejects an unknown conversationId", %{conn: conn} do
      insert(:conversation, user: conn.assigns.current_user, prepend_context: [])

      conn =
        post(conn, "/v2/chats/message", %{
          "message" => "How do functions work?",
          "conversationId" => 999_999_999
        })

      assert response(conn, :not_found) == "Conversation not found"
    end

    @tag authenticate: :student
    test "rejects a non-SICPy language for a message", %{conn: conn} do
      insert(:conversation, user: conn.assigns.current_user, prepend_context: [])

      conn =
        post(conn, "/v2/chats/message", %{
          "message" => "How do functions work?",
          "languageId" => "source2"
        })

      assert response(conn, :bad_request) == "Unsupported languageId"
    end
  end
end

defmodule CadetWeb.ChatControllerTest.FakeRetriever do
  def retrieve(query, opts) do
    send(self(), {:vector_rag_retrieved, query, opts})
    {:ok, [%{title: "Python notes", content: "Python uses def to define functions."}]}
  end
end

defmodule CadetWeb.ChatControllerTest.EmptyRetriever do
  def retrieve(_query, _opts), do: {:ok, []}
end
