defmodule Cadet.Accounts.User do
  @moduledoc """
  The User entity represents a user.
  It stores basic information such as name and role
  Each user is associated to one `role` which determines the access level
  of the user.
  """
  use Cadet, :model

  alias Cadet.Accounts.Role
  alias Cadet.Course.Group

  schema "users" do
    field(:name, :string)
    field(:role, Role)
    field(:nusnet_id, :string)
    belongs_to(:group, Group)
    timestamps()
  end

  @required_fields ~w(name role)a
  @optional_fields ~w(nusnet_id)a

  def changeset(user, params \\ %{}) do
    user
    |> cast(params, @required_fields ++ @optional_fields)
    |> validate_required(@required_fields)
  end

  def student_changeset(student, params) do
    student
    |> cast(params, @required_fields ++ @optional_fields)
    |> add_belongs_to_id_from_model(:group, params)
  end
end
