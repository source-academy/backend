defmodule Cadet.Chatbot.LlmConversations do
  @moduledoc """
  LLM Conversation service provides functions to create, update, and fetch LLM conversations.
  Each user is locked to exactly one conversation.
  """
  use Cadet, [:context, :display]

  import Ecto.Query
  require Logger

  alias Cadet.Chatbot.Conversation

  @doc """
  Gets the single conversation for a user. Each user has exactly one conversation.
  If multiple exist (from old data), returns the most recent one.
  Returns {:ok, conversation} if found, {:error, {:not_found, message}} if not.
  """
  @spec get_conversation_for_user(binary() | integer()) ::
          {:ok, Conversation.t()} | {:error, {:not_found, binary()}}
  def get_conversation_for_user(user_id) when is_ecto_id(user_id) do
    Logger.info("Fetching conversation for user #{user_id}")

    case Conversation
         |> where([c], c.user_id == ^user_id)
         |> where([c], c.prepend_context == ^[])
         |> order_by([c], desc: c.inserted_at)
         |> limit(1)
         |> Repo.one() do
      nil ->
        Logger.info("No conversation found for user #{user_id}")
        {:error, {:not_found, "Conversation not found"}}

      conversation ->
        Logger.info("Found conversation #{conversation.id} for user #{user_id}")
        {:ok, conversation}
    end
  end

  @doc """
  Gets or creates the single conversation for a user.
  If user already has a conversation, returns it.
  If not, creates a new one.
  """
  @spec get_or_create_conversation(binary() | integer()) ::
          {:ok, Conversation.t()} | {:error, binary()}
  def get_or_create_conversation(user_id) when is_ecto_id(user_id) do
    Logger.info("Getting or creating conversation for user #{user_id}")

    case get_conversation_for_user(user_id) do
      {:ok, conversation} ->
        Logger.info("User #{user_id} already has conversation #{conversation.id}")
        {:ok, conversation}

      {:error, {:not_found, _}} ->
        Logger.info("Creating new conversation for user #{user_id}")
        create_new_conversation(user_id)
    end
  end

  @doc """
  Creates a new conversation for a user. Should only be called when user has no existing conversation.
  """
  @spec create_new_conversation(binary() | integer()) ::
          {:ok, Conversation.t()} | {:error, binary()}
  defp create_new_conversation(user_id) do
    Logger.info("Creating a new conversation for user #{user_id}")

    case %Conversation{
           user_id: user_id,
           prepend_context: [],
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
    updated_messages =
      conversation.messages ++
        [%{role: role, content: content, created_at: DateTime.utc_now()}]

    changeset =
      if conversation.guest_uuid do
        Conversation.guest_changeset(conversation, %{messages: updated_messages})
      else
        Conversation.changeset(conversation, %{messages: updated_messages})
      end

    case Repo.update(changeset) do
      {:ok, updated} -> {:ok, updated}
      {:error, changeset} -> {:error, full_error_messages(changeset)}
    end
  end

  @system_error_message "An error occurred while generating a response. The conversation continues below."

  def add_error_message(conversation) do
    add_message(conversation, "system", @system_error_message)
  end

  @spec get_conversation_for_guest(String.t()) ::
          {:ok, Conversation.t()} | {:error, {:not_found, String.t()}}
  def get_conversation_for_guest(guest_uuid) when is_binary(guest_uuid) do
    Logger.debug("Fetching conversation for guest #{guest_uuid}")

    case Conversation
         |> where([c], c.guest_uuid == ^guest_uuid)
         |> where([c], c.prepend_context == ^[])
         |> order_by([c], desc: c.inserted_at)
         |> limit(1)
         |> Repo.one() do
      nil ->
        Logger.debug("No conversation found for guest #{guest_uuid}")
        {:error, {:not_found, "Conversation not found"}}

      conversation ->
        Logger.debug("Found conversation #{conversation.id} for guest #{guest_uuid}")
        {:ok, conversation}
    end
  end

  @spec get_or_create_conversation_for_guest(String.t()) ::
          {:ok, Conversation.t()} | {:error, String.t()}
  def get_or_create_conversation_for_guest(guest_uuid) when is_binary(guest_uuid) do
    Logger.debug("Getting or creating conversation for guest #{guest_uuid}")

    case get_conversation_for_guest(guest_uuid) do
      {:ok, conversation} ->
        Logger.debug("Guest #{guest_uuid} already has conversation #{conversation.id}")
        {:ok, conversation}

      {:error, {:not_found, _}} ->
        Logger.debug("Creating new conversation for guest #{guest_uuid}")
        create_new_conversation_for_guest(guest_uuid)
    end
  end

  @spec create_new_conversation_for_guest(String.t()) ::
          {:ok, Conversation.t()} | {:error, String.t()}
  defp create_new_conversation_for_guest(guest_uuid) do
    Logger.debug("Creating a new conversation for guest #{guest_uuid}")

    case %Conversation{
           guest_uuid: guest_uuid,
           prepend_context: [],
           messages: [get_initial_message()]
         }
         |> Conversation.guest_changeset(%{})
         |> Repo.insert() do
      {:ok, conversation} ->
        Logger.debug(
          "Successfully created conversation #{conversation.id} for guest #{guest_uuid}."
        )

        {:ok, conversation}

      {:error, changeset} ->
        error_msg = full_error_messages(changeset)
        Logger.error("Failed to create conversation for guest #{guest_uuid}: #{error_msg}")
        {:error, error_msg}
    end
  end

  defp get_initial_message do
    %{
      role: "assistant",
      content: "Ask me something about this paragraph!",
      created_at: DateTime.utc_now()
    }
  end
end
