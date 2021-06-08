defmodule Cadet.Accounts.User do
  @moduledoc """
  The User entity represents a user.
  It stores basic information such as name and role
  Each user is associated to one `role` which determines the access level
  of the user.
  """
  use Cadet, :model

  alias Cadet.Accounts.CourseRegistration
  alias Cadet.Courses.Course

  schema "users" do
    field(:name, :string)
    field(:username, :string)

    belongs_to(:latest_viewed, Course)
    has_many(:course_registration, CourseRegistration)

    timestamps()
  end

  @required_fields ~w(name)a
  @optional_fields ~w(username latest_viewed_id)a

  def changeset(user, params \\ %{}) do
    user
    |> cast(params, @required_fields ++ @optional_fields)
    |> validate_required(@required_fields)
    |> foreign_key_constraint(:latest_viewed_id)
  end
end
