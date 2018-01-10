defmodule Cadet.Accounts.Form.Registration do
  use Ecto.Schema

  import Ecto.Changeset

  embedded_schema do
    field(:first_name, :string)
    field(:last_name, :string)
    field(:email, :string)
    field(:password, :string)
    field(:password_confirmation, :string)
  end

  @required_fields ~w(first_name email password password_confirmation)a
  @optional_fields ~w(last_name)a

  @email_format ~r/^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,4}$/

  def changeset(registration, params \\ :empty) do
    registration
    |> cast(params, @required_fields ++ @optional_fields)
    |> validate_required(@required_fields)
    |> validate_format(:email, @email_format)
    |> validate_length(:password, min: 8)
    |> validate_confirmation(:password)
  end
end
