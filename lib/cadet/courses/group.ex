defmodule Cadet.Courses.Group do
  @moduledoc """
  The Group entity represent relations between student
  and discussion group leader
  """
  use Cadet, :model

  alias Cadet.Accounts.CourseRegistration
  alias Cadet.Courses.Course

  schema "groups" do
    field(:name, :string)
    belongs_to(:leader, CourseRegistration)
    belongs_to(:mentor, CourseRegistration)
    belongs_to(:course, Course)

    has_many(:students, CourseRegistration)
  end

  @required_fields ~w(name course_id)a
  @optional_fields ~w(leader_id mentor_id)a

  def changeset(group, attrs \\ %{}) do
    group
    |> cast(attrs, @required_fields ++ @optional_fields)
    |> validate_required(@required_fields)
    |> add_belongs_to_id_from_model([:leader, :mentor, :course], attrs)
  end
end
