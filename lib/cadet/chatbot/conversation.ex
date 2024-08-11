defmodule Cadet.Chatbot.Conversation do
  @moduledoc """
  The Conversation entity stores the messages exchanged between the user and the chatbot.
  """
  use Cadet, :model

  alias Cadet.Accounts.User

  @type t :: %__MODULE__{
          user: User.t(),
          # { role: string; content: string }[]
          prepend_context: list(map()),
          # { role: string; content: string, createdAt: string }[]
          messages: list(map())
        }

  schema "llm_chats" do
    field(:prepend_context, {:array, :map}, default: [])
    field(:messages, {:array, :map}, default: [])

    belongs_to(:user, User)

    timestamps()
  end

  @required_fields ~w(user_id)a
  @optional_fields ~w(prepend_context messages)a

  def changeset(conversation, params) do
    conversation
    |> cast(params, @required_fields ++ @optional_fields)
    |> add_belongs_to_id_from_model([:user], params)
    |> validate_required(@required_fields)
  end
end
