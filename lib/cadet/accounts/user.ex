defmodule Cadet.Accounts.User do
  @moduledoc """
  The User entity represents a user.
  It stores basic information such as name
  """
  use Cadet, :model

  alias Cadet.Accounts.CourseRegistration
  alias Cadet.Courses.Course

  schema "users" do
    field(:name, :string)
    field(:username, :string)

    belongs_to(:latest_viewed_course, Course)
    has_many(:courses, CourseRegistration)

    timestamps()
  end

  @required_fields ~w(username)a
  @optional_fields ~w(name latest_viewed_course_id)a

  def changeset(user, params \\ %{}) do
    user
    |> cast(params, @required_fields ++ @optional_fields)
    |> validate_required(@required_fields)
    |> foreign_key_constraint(:latest_viewed_course_id)
  end
end
