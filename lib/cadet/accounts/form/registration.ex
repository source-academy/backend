defmodule Cadet.Accounts.Form.Registration do
  @moduledoc """
  The Accounts.Form entity represents an entry from a /auth call, where the
  LumiNUS authentication token corresponds to a user who has not been registered
  in our database.
  """

  use Ecto.Schema

  import Ecto.Changeset

  embedded_schema do
    field(:name, :string)
    field(:nusnet_id, :string)
  end

  @required_fields ~w(name nusnet_id)a

  def changeset(registration, params \\ %{}) do
    registration
    |> cast(params, @required_fields)
    |> validate_required(@required_fields)
  end
end
