defmodule Cadet.Accounts.Form.Login do
  @moduledoc """
  The Accounts.Form entity represents an entry from an accounts form.
  A login form comprises of an IVLE authentication token.
  """
  use Ecto.Schema

  import Ecto.Changeset

  embedded_schema do
    field(:ivle_token, :string)
  end

  @required_fields ~w(ivle_token)a

  def changeset(login, params \\ %{}) do
    login
    |> cast(params, @required_fields)
    |> validate_required(@required_fields)
  end
end
