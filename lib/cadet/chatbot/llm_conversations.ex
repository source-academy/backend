defmodule Cadet.Chatbot.LlmConversations do
  @moduledoc """
  LLM Conversation service provides functions to create, update, and fetch LLM conversations.
  """
  use Cadet, [:context, :display]

  import Ecto.Query
  require Logger

  alias Cadet.Chatbot.{Conversation, PromptBuilder}

  # WARNING: unrestricted access to all conversations
  def get_conversation(id) when is_ecto_id(id) do
    Repo.get(Conversation, id)
  end

  # Secured against unauthorized access
  def get_conversation_for_user(user_id, conversation_id)
      when is_ecto_id(user_id) and is_ecto_id(conversation_id) do
    Logger.info("Fetching LLM conversation #{conversation_id} for user #{user_id}")

    conversation = get_conversation(conversation_id)

    case conversation do
      nil ->
        Logger.error("Conversation #{conversation_id} not found for user #{user_id}.")

        {:error, {:not_found, "Conversation not found"}}

      conversation when conversation.user_id == user_id ->
        Logger.info("Successfully retrieved conversation #{conversation_id} for user #{user_id}.")

        {:ok, conversation}

      # user_id does not match, intentionally vague error message
      %Conversation{} ->
        Logger.error(
          "User #{user_id} is not authorized to access conversation #{conversation_id}."
        )

        {:error, {:not_found, "Conversation not found"}}

      _ ->
        Logger.error(
          "Unexpected error while fetching conversation #{conversation_id} for user #{user_id}."
        )

        {:error, {:internal_server_error, "An unexpected error occurred"}}
    end
  end

  def get_conversations(user_id) when is_ecto_id(user_id) do
    Logger.info("Fetching all conversations for user #{user_id}")

    Conversation
    |> where([c], c.user_id == ^user_id)
    |> Repo.all()
  end

  @spec create_conversation(binary() | integer(), binary(), binary()) ::
          {:error, binary()} | {:ok, Conversation.t()}
  def create_conversation(user_id, section, visible_paragraph_texts)
      when is_ecto_id(user_id) and is_binary(section) and is_binary(visible_paragraph_texts) do
    Logger.info("Creating a new conversation for user #{user_id} in section #{section}")

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
      {:ok, conversation} ->
        Logger.info("Successfully created conversation #{conversation.id} for user #{user_id}.")

        {:ok, conversation}

      {:error, changeset} ->
        error_msg = full_error_messages(changeset)

        Logger.error("Failed to create conversation for user #{user_id}: #{error_msg}")

        {:error, error_msg}
    end
  end

  def add_message(conversation, role, content) do
    case conversation
         |> Conversation.changeset(%{
           messages:
             conversation.messages ++
               [%{role: role, content: content, created_at: DateTime.utc_now()}]
         })
         |> Repo.update() do
      {:ok, updated} -> {:ok, updated}
      {:error, changeset} -> {:error, full_error_messages(changeset)}
    end
  end

  @system_error_message "An error occurred while generating a response. The conversation continues below."

  def add_error_message(conversation) do
    add_message(conversation, "system", @system_error_message)
  end

  defp get_initial_message do
    %{
      role: "assistant",
      content: "Ask me something about this paragraph!",
      created_at: DateTime.utc_now()
    }
  end
end
