defmodule Cadet.Accounts.User do
  @moduledoc """
  The User entity represents a user.
  It stores basic information such as name and role
  Each user is associated to one `role` which determines the access level
  of the user.
  """
  use Cadet, :model

  # alias Cadet.Accounts.Role
  # alias Cadet.Course.Group

  schema "users" do
    field(:name, :string)
    # field(:role, Role)
    field(:username, :string)
    # field(:game_states, :map)
    # belongs_to(:group, Group)
    timestamps()
  end

  # @required_fields ~w(name role)a
  @required_fields ~w(name)a
  # @optional_fields ~w(username group_id game_states)a
  @optional_fields ~w(username)a

  def changeset(user, params \\ %{}) do
    user
    |> cast(params, @required_fields ++ @optional_fields)
    # |> add_belongs_to_id_from_model(:group, params)
    |> validate_required(@required_fields)
  end
end
