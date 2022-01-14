defmodule Cadet.Accounts.CourseRegistration do
  @moduledoc """
  The mapping table representing the registration of a user to a course.
  """
  use Cadet, :model

  alias Cadet.Accounts.{Role, User}
  alias Cadet.Courses.{Course, Group}

  @type t :: %__MODULE__{
          role: Role.t(),
          game_states: %{},
          agreed_to_research: boolean(),
          group: Group.t() | nil,
          user: User.t() | nil,
          course: Course.t() | nil
        }

  schema "course_registrations" do
    field(:role, Role)
    field(:game_states, :map)
    field(:agreed_to_research, :boolean)

    belongs_to(:group, Group)
    belongs_to(:user, User)
    belongs_to(:course, Course)

    timestamps()
  end

  @required_fields ~w(user_id course_id role)a
  @optional_fields ~w(game_states group_id agreed_to_research)a

  def changeset(course_registration, params \\ %{}) do
    course_registration
    |> cast(params, @optional_fields ++ @required_fields)
    |> add_belongs_to_id_from_model([:user, :group, :course], params)
    |> validate_required(@required_fields)
    |> unique_constraint(:user_id, name: :course_registrations_user_id_course_id_index)
  end
end
