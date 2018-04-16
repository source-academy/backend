defmodule Cadet.Accounts.Form.Login do
  @moduledoc """
  Validates login information provided through forms.
  """
  use Ecto.Schema

  import Ecto.Changeset

  embedded_schema do
    field(:email, :string)
    field(:password, :string)
  end

  @required_fields ~w(email password)a

  def changeset(login, params \\ %{}) do
    login
    |> cast(params, @required_fields)
    |> validate_required(@required_fields)
  end
end
