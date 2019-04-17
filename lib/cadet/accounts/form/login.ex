defmodule Cadet.Accounts.Form.Login do
  @moduledoc """
  The Accounts.Form entity represents an entry from an accounts form.
  A login form comprises of an LumiNUS authentication token.
  """
  use Ecto.Schema

  import Ecto.Changeset

  embedded_schema do
    field(:luminus_code, :string)
  end

  @required_fields ~w(luminus_code)a

  def changeset(login, params \\ %{}) do
    login
    |> cast(params, @required_fields)
    |> validate_required(@required_fields)
  end
end
