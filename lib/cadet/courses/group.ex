defmodule Cadet.Courses.Group do
  @moduledoc """
  The Group entity represent relations between student
  and discussion group leader
  """
  use Cadet, :model

  alias Cadet.Accounts.User

  schema "groups" do
    field(:name, :string)
    belongs_to(:leader, CourseRegistration)
    belongs_to(:mentor, CourseRegistration)

    has_many(:students, CourseRegistration)
  end

  @optional_fields ~w(name leader_id mentor_id)a

  def changeset(group, attrs \\ %{}) do
    group
    |> cast(attrs, @optional_fields)
    |> add_belongs_to_id_from_model([:leader, :mentor], attrs)
  end
end
