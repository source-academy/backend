defmodule Cadet.Accounts.User do
  @moduledoc """
  The User entity represents a user.
  It stores basic information such as name and role
  Each user is associated to one `role` which determines the access level
  of the user.
  """
  use Cadet, :model

  alias Cadet.Accounts.Role

  schema "users" do
    field(:name, :string)
    field(:role, Role)

    timestamps()
  end

  @required_fields ~w(name role)a

  def changeset(user, params \\ %{}) do
    user
    |> cast(params, @required_fields)
    |> validate_required(@required_fields)
    |> validate_inclusion(:role, Role.__valid_values__())
  end
end
