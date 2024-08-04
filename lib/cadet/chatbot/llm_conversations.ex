defmodule Cadet.Chatbot.LlmConversations do
  @moduledoc """
  LLM Conversation service provides functions to create, update, and fetch LLM conversations.
  """
  use Cadet, [:context, :display]

  import Ecto.Query

  alias Cadet.Chatbot.{Conversation, PromptBuilder}

  # WARNING: unrestricted access to all conversations
  def get_conversation(id) when is_ecto_id(id) do
    Repo.get(Conversation, id)
  end

  # Secured against unauthorized access
  def get_conversation_for_user(user_id, conversation_id)
      when is_ecto_id(user_id) and is_ecto_id(conversation_id) do
    conversation = get_conversation(conversation_id)

    case conversation do
      nil -> {:error, "Conversation not found"}
      conversation when conversation.user_id == user_id -> {:ok, conversation}
      # user_id does not match, intentionally vague error message
      _ -> {:error, "Conversation not found"}
    end
  end

  def get_conversations(user_id) when is_ecto_id(user_id) do
    Conversation
    |> where([c], c.user_id == ^user_id)
    |> Repo.all()
  end

  @spec create_conversation(binary() | integer(), binary(), binary()) ::
          {:error, binary()} | {:ok, Conversation.t()}
  def create_conversation(user_id, section, visible_paragraph_texts)
      when is_ecto_id(user_id) and is_binary(section) and is_binary(visible_paragraph_texts) do
    context = [
      %{role: "system", content: PromptBuilder.build_prompt(section, visible_paragraph_texts)}
    ]

    case %Conversation{
           user_id: user_id,
           prepend_context: context,
           messages: [get_initial_message()]
         }
         |> Conversation.changeset(%{})
         |> Repo.insert() do
      {:ok, conversation} -> {:ok, conversation}
      {:error, changeset} -> {:error, full_error_messages(changeset)}
    end
  end

  def add_message(conversation, role, content) do
    case conversation
         |> Conversation.changeset(%{
           messages: conversation.messages ++ [%{role: role, content: content}]
         })
         |> Repo.update() do
      {:ok, updated} -> {:ok, updated}
      {:error, changeset} -> {:error, full_error_messages(changeset)}
    end
  end

  defp get_initial_message do
    %{role: "bot", content: "Ask me something about this paragraph!"}
  end
end
