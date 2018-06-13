defmodule Cadet.Accounts.Form.Registration do
  @moduledoc """
  The Accounts.Form entity represents an entry from an accounts form.
  A registration form contains the same information as the User and Authorization
  entity, including name, NUSNET ID, password, and password confirmation.
  """

  use Ecto.Schema

  import Ecto.Changeset

  embedded_schema do
    field(:name, :string)
    field(:nusnet_id, :string)
    field(:password, :string)
    field(:password_confirmation, :string)
  end

  @required_fields ~w(name nusnet_id password password_confirmation)a

  def changeset(registration, params \\ %{}) do
    registration
    |> cast(params, @required_fields)
    |> validate_required(@required_fields)
    |> validate_length(:password, min: 8)
    |> validate_confirmation(:password)
  end
end
