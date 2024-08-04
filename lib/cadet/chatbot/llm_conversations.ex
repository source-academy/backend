defmodule Cadet.Chatbot.LlmConversations do
  @moduledoc """
  LLM Convestation service provides functions to create, update, and fetch LLM conversations.
  """
  use Cadet, [:context, :display]

  import Ecto.Query

  alias Cadet.Chatbot.Conversation
  alias Cadet.Chatbot.PromptBuilder

  def get_conversation(id) when is_ecto_id(id) do
    Repo.get(Conversation, id)
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
    messages = [
      %{role: "system", content: PromptBuilder.build_prompt(section, visible_paragraph_texts)},
      get_initial_message()
    ]

    case %Conversation{user_id: user_id, messages: messages}
         |> Conversation.changeset(%{})
         |> Repo.insert() do
      {:ok, conversation} -> {:ok, conversation}
      {:error, changeset} -> {:error, full_error_messages(changeset)}
    end
  end

  def add_message(conversation, role, content) do
    conversation
    |> put_in([:messages], conversation.messages ++ [%{role: role, content: content}])
    |> Conversation.changeset(%{})
    |> Repo.update()
  end

  defp get_initial_message() do
    %{role: "bot", content: "Ask me something about this paragraph!"}
  end
end
