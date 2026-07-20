defmodule CadetWeb.Schemas.ConversationInit do
  @moduledoc false
  require OpenApiSpex
  alias OpenApiSpex.Schema

  OpenApiSpex.schema(%{
    title: "ConversationInit",
    description: "A freshly initialised (or existing) chatbot conversation",
    type: :object,
    properties: %{
      conversationId: %Schema{type: :integer, description: "Conversation id"},
      messages: %Schema{
        type: :array,
        items: %Schema{type: :object},
        description: "Existing messages in the conversation"
      },
      maxContentSize: %Schema{
        type: :integer,
        description: "Maximum allowed length of a user message"
      }
    },
    required: [:conversationId]
  })
end

defmodule CadetWeb.Schemas.ConversationResponse do
  @moduledoc false
  require OpenApiSpex
  alias OpenApiSpex.Schema

  OpenApiSpex.schema(%{
    title: "ConversationResponse",
    description: "A chatbot response to a user message",
    type: :object,
    properties: %{
      conversationId: %Schema{type: :integer, description: "Conversation id"},
      response: %Schema{type: :string, description: "The chatbot's reply"}
    },
    required: [:conversationId, :response]
  })
end

defmodule CadetWeb.Schemas.ChatMessageRequest do
  @moduledoc false
  require OpenApiSpex
  alias OpenApiSpex.Schema

  OpenApiSpex.schema(%{
    title: "ChatMessageRequest",
    description: "A user message sent to the section chatbot",
    type: :object,
    properties: %{
      message: %Schema{type: :string, description: "The user's message"},
      section: %Schema{type: :string, description: "The section the user is in"},
      initialContext: %Schema{type: :string, description: "Text visible to the user"}
    },
    required: [:message, :section, :initialContext]
  })
end

defmodule CadetWeb.Schemas.RagChatMessageRequest do
  @moduledoc false
  require OpenApiSpex
  alias OpenApiSpex.Schema

  OpenApiSpex.schema(%{
    title: "RagChatMessageRequest",
    description: "A user message sent to the RAG chatbot",
    type: :object,
    properties: %{
      message: %Schema{type: :string, description: "The user's message"}
    },
    required: [:message]
  })
end
