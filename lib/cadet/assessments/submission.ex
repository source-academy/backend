defmodule Cadet.Assessments.Submission do
  @moduledoc false
  use Cadet, :model

  import Ecto.Query

  alias Cadet.Assessments.Assessment
  alias Cadet.Assessments.SubmissionStatus
  alias Cadet.Accounts.User
  alias Cadet.Assessments.Mission
  alias Cadet.Assessments.Answer

  schema "submissions" do
    field(:status, SubmissionStatus, default: :attempting)
    field(:submitted_at, Timex.Ecto.DateTime)
    field(:override_xp, :integer)

    belongs_to(:mission, Mission)
    belongs_to(:student, User)
    belongs_to(:grader, User)
    has_many(:answers, Answer)

    timestamps()
  end

  @required_fields ~w(status)a
  @optional_fields ~w(override_xp submitted_at)a

  def changeset(submission, params) do
    params = convert_date(params, "submitted_at")

    submission
    |> cast(params, @required_fields ++ @optional_fields)
    |> validate_required(@required_fields)

    #  |> validate_role(:student, "student")
    #  |> validate_role(:grader, "staff")
  end

  # def validate_role(changeset, user, role) do
  #  validate_change(changeset, user, fn ^user, user ->
  #    case user.role == ^role do
  #      true -> []
  #      false -> [{^user, "Access Denied"}]
  #    end
  #  end)
  # end

  def convert_date(params, field) do
    if params[field] != "" && params[field] != nil do
      timezone = Timezone.get("Asia/Singapore", Timex.now())

      date =
        params[field]
        |> String.to_integer()
        |> Timex.from_unix(:millisecond)
        |> Timezone.convert(timezone)

      Map.put(params, field, date)
    else
      params
    end
  end
end
