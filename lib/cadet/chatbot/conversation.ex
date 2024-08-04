defmodule Cadet.Chatbot.Conversation do
  @moduledoc """
  The Conversation entity stores the messages exchanged between the user and the chatbot.
  """
  use Cadet, :model

  @type t :: %__MODULE__{
          user_id: integer(),
          # { role: string; content: string }[]
          messages: list(map())
        }

  schema "llm_chats" do
    field(:user_id, :integer)
    field(:messages, {:array, :map}, default: [])

    timestamps()
  end

  @required_fields ~w(user_id)a
  @optional_fields ~w(messages)a

  def changeset(conversation, params) do
    conversation
    |> cast(params, @required_fields ++ @optional_fields)
    |> validate_required(@required_fields)
  end
end
