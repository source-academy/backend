defmodule Cadet.Chatbot.RagConversations do
  use Cadet, [:context, :display]

  import Ecto.Query
  require Logger

  alias Cadet.Chatbot.Conversation

  @rag_tag [%{"chat_type" => "rag"}]

  def get_conversation_for_user(user_id) when is_ecto_id(user_id) do
    Logger.info("Fetching RAG conversation for user #{user_id}")

    case Conversation
         |> where([c], c.user_id == ^user_id)
         |> where([c], c.prepend_context == ^@rag_tag)
         |> order_by([c], desc: c.inserted_at)
         |> limit(1)
         |> Repo.one() do
      nil ->
        Logger.info("No RAG conversation found for user #{user_id}")
        {:error, {:not_found, "Conversation not found"}}

      conversation ->
        Logger.info("Found RAG conversation #{conversation.id} for user #{user_id}")
        {:ok, conversation}
    end
  end

  def get_or_create_conversation(user_id) when is_ecto_id(user_id) do
    case get_conversation_for_user(user_id) do
      {:ok, conversation} ->
        {:ok, conversation}

      {:error, {:not_found, _}} ->
        Logger.info("Creating new RAG conversation for user #{user_id}")
        create_conversation(user_id)
    end
  end

  defp create_conversation(user_id) do
    case %Conversation{
           user_id: user_id,
           prepend_context: @rag_tag,
           messages: [initial_message()]
         }
         |> Conversation.changeset(%{})
         |> Repo.insert() do
      {:ok, conversation} ->
        Logger.info("Created RAG conversation #{conversation.id} for user #{user_id}")
        {:ok, conversation}

      {:error, changeset} ->
        error_msg = full_error_messages(changeset)
        Logger.error("Failed to create RAG conversation for user #{user_id}: #{error_msg}")
        {:error, error_msg}
    end
  end

  defp initial_message do
    %{
      role: "assistant",
      content:
        "Hi! I'm your course assistant. Ask me about lectures, tutorials, recitations, or past exams!",
      created_at: DateTime.utc_now()
    }
  end
end
