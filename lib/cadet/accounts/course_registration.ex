defmodule Cadet.Accounts.CourseRegistration do
  @moduledoc """
  The mapping table representing the registration of a user to a course.
  """
  use Cadet, :model

  alias Cadet.Accounts.{Role, User}
  alias Cadet.Courses.{Course, Group}

  schema "course_registrations" do
    field(:role, Role)
    field(:game_states, :map)

    belongs_to(:group, Group)
    belongs_to(:user, User)
    belongs_to(:course, Course)

    timestamps()
  end

  @required_fields ~w(user_id course_id role)a
  @optional_fields ~w(game_states group_id)a

  def changeset(course_registration, params \\ %{}) do
    course_registration
    |> cast(params, @optional_fields ++ @required_fields)
    |> add_belongs_to_id_from_model([:user, :group, :course], params)
    |> validate_required(@required_fields)
  end
end
