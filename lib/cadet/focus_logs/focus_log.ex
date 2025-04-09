defmodule Cadet.FocusLogs.FocusLog do
  @moduledoc """
  The FocusLog entity represents a log of user's browser focus
  while using Source Academy under exam mode.
  """
  use Cadet, :model

  alias Cadet.Accounts.User
  alias Cadet.Courses.Course

  @type t :: %__MODULE__{
          user: User.t(),
          course: Course.t(),
          focus_type: integer()
        }

  schema "user_browser_focus_log" do
    belongs_to(:user, User)
    belongs_to(:course, Course)
    field(:time, :naive_datetime)
    field(:focus_type, :integer)
  end

  @required_fields ~w(user_id course_id time focus_type)a

  def changeset(focus_log, params) do
    focus_log
    |> cast(params, @required_fields)
    |> add_belongs_to_id_from_model([:user, :course], params)
    |> validate_required(@required_fields)
  end
end
