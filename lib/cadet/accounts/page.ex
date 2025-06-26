defmodule Cadet.Accounts.Page do
  @moduledoc """
  The Page entity represents data about a specific page,
  as of now it just contains time spent at the page.
  """

  use Cadet, :model
  alias Cadet.Accounts.{CourseRegistration, User}
  alias Cadet.Courses.Course

  schema "pages" do
    field(:path, :string)
    field(:time_spent, :integer)

    belongs_to(:user, User)
    belongs_to(:course_registration, CourseRegistration, type: :integer)
    belongs_to(:course, Course)

    timestamps()
  end

  @required_fields ~w(user_id path time_spent)a
  @optional_fields ~w(course_registration_id course_id)a

  def changeset(page, params \\ %{}) do
    page
    |> cast(params, @required_fields ++ @optional_fields)
    |> validate_required(@required_fields)
    |> foreign_key_constraint(:user_id)
    |> foreign_key_constraint(:course_registration_id)
    |> foreign_key_constraint(:course_id)
  end
end
