defmodule Cadet.Notebooks.Notebook do
  @moduledoc """
  The Notebook entity stores metadata of a notebook
  """
  use Cadet, :model

  alias Cadet.Courses.Course
  alias Cadet.Accounts.{User, CourseRegistration}

  schema "notebooks" do
    field(:title, :string)
    field(:config, :string)
    field(:is_published, :boolean, default: false)
    field(:pin_order, :integer)

    belongs_to(:course, Course)
    # author
    belongs_to(:user, User)
    # to get role
    belongs_to(:course_registration, CourseRegistration)

    timestamps()
  end

  @required_fields ~w(title config course user course_registration pin_order)a
  @optional_fields ~w(is_published)a

  def changeset(notebooks, attrs \\ %{}) do
    notebooks
    |> cast(attrs, @required_fields ++ @optional_fields)
    |> validate_required(@required_fields)
    |> add_belongs_to_id_from_model([:user, :course_registration, :course], attrs)
  end
end
