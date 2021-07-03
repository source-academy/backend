defmodule Cadet.Courses.Group do
  @moduledoc """
  The Group entity represent relations between student
  and discussion group leader
  """
  use Cadet, :model

  alias Cadet.Repo
  alias Cadet.Accounts.CourseRegistration
  alias Cadet.Courses.Course

  schema "groups" do
    field(:name, :string)
    belongs_to(:leader, CourseRegistration)
    belongs_to(:course, Course)

    has_many(:students, CourseRegistration)
  end

  @required_fields ~w(name course_id)a
  @optional_fields ~w(leader_id)a

  def changeset(group, attrs \\ %{}) do
    group
    |> cast(attrs, @required_fields ++ @optional_fields)
    |> validate_required(@required_fields)
    |> add_belongs_to_id_from_model([:leader, :course], attrs)
    |> validate_role

    # |> validate_course
  end

  defp validate_role(changeset) do
    leader_id = get_field(changeset, :leader_id)

    if leader_id != nil && Repo.get(CourseRegistration, leader_id).role != :staff do
      add_error(changeset, :leader, "is not a staff")
    else
      changeset
    end
  end

  # defp validate_course(changeset) do
  #   course_id = get_field(changeset, :course_id)
  #   leader_id = get_field(changeset, :leader_id)

  #   if leader_id != nil && Repo.get(CourseRegistration, leader_id).course_id != course_id do
  #     add_error(changeset, :leader, "does not belong to the same course ")
  #   end

  # end
end
