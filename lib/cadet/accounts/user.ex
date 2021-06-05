defmodule Cadet.Accounts.User do
  @moduledoc """
  The User entity represents a user.
  It stores basic information such as name and role
  Each user is associated to one `role` which determines the access level
  of the user.
  """
  use Cadet, :model

  alias Cadet.Accounts.CourseRegistration

  schema "users" do
    field(:name, :string)
    field(:username, :string)

    has_many(:course_registration, CourseRegistration)

    timestamps()
  end

  @required_fields ~w(name)a
  @optional_fields ~w(username)a

  def changeset(user, params \\ %{}) do
    user
    |> cast(params, @required_fields ++ @optional_fields)
    # |> add_belongs_to_id_from_model(:group, params)
    |> validate_required(@required_fields)
  end
end
