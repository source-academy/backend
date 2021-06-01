defmodule Cadet.Accounts.CourseRegistration do
  @moduledoc """
  The mapping table representing the registration of a user to a course.
  """
  use Cadet, :model

  alias Cadet.Course.{Courses, Group}

  schema "course_registrations" do
    field(:role, Role)
    field(:game_states, :map)

    belongs_to(:group, Courses.Group)
    belongs_to(:user, User)
    belongs_to(:course, Courses)

    timestamps()
  end

  # @optional_fields ~w(name leader_id mentor_id)a

  # def changeset(group, attrs \\ %{}) do
  #   group
  #   |> cast(attrs, @optional_fields)
  #   |> add_belongs_to_id_from_model([:leader, :mentor], attrs)
  # end
end
