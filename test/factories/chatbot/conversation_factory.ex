defmodule Cadet.Chatbot.ConversationFactory do
  @moduledoc """
  Factories for Cadet.Chatbot.Conversation entity.
  """

  defmacro __using__(_opts) do
    quote do
      alias Cadet.Chatbot.Conversation

      def conversation_factory do
        %Conversation{
          user: build(:user),
          prepend_context: [%{role: "system", content: "You are a helpful assistant."}],
          messages: [%{role: "assistant", content: "Hello, how can I help you?"}]
        }
      end
    end
  end
end
