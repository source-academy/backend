defmodule Cadet.Chatbot.Conversation do
  @moduledoc """
  The Conversation entity stores the messages exchanged between the user and the chatbot.
  """
  use Cadet, :model

  alias Cadet.Accounts.User

  @type t :: %__MODULE__{
          user: User.t(),
          language_id: String.t() | nil,
          prepend_context: list(map()),
          messages: list(map())
        }

  schema "llm_chats" do
    field(:prepend_context, {:array, :map}, default: [])
    field(:messages, {:array, :map}, default: [])
    field(:language_id, :string)

    belongs_to(:user, User)

    timestamps()
  end

  @required_fields ~w(user_id)a
  @optional_fields ~w(prepend_context messages language_id)a

  def changeset(conversation, params) do
    conversation
    |> cast(params, @required_fields ++ @optional_fields)
    |> add_belongs_to_id_from_model([:user], params)
    |> validate_required(@required_fields)
  end
end
