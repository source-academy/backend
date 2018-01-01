defmodule Cadet.Accounts.Registration do
  defstruct first_name: "", last_name: "", email: "", password: "", password_confirmation: ""

  import Ecto.Changeset

  @types %{
    first_name: :string,
    last_name: :string,
    email: :string,
    password: :string,
    password_confirmation: :string
  }

  @required_fields ~w(first_name email password password_confirmation)a
  @optional_fields ~w(last_name)a

  @email_format ~r/^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,4}$/

  def changeset(registration, params \\ :empty) do
    {registration, @types}
    |> cast(params, @required_fields ++ @optional_fields)
    |> validate_required(@required_fields)
    |> validate_format(:email, @email_format)
    |> validate_length(:password, min: 8)
    |> validate_confirmation(:password)
  end
end
