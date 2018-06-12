defmodule Cadet.Assessments.Submission do
  @moduledoc false
  use Cadet, :model

<<<<<<< HEAD
=======
  import Ecto.Query

>>>>>>> d08d50a55138354557a30d45d5423d8531f5c5b1
  alias Cadet.Assessments.Assessment
  alias Cadet.Assessments.SubmissionStatus
  alias Cadet.Accounts.User
  alias Cadet.Assessments.Mission
  alias Cadet.Assessments.Answer

  schema "submissions" do
<<<<<<< HEAD
    field :status, SubmissionStatus, default: :attempting
    field :submitted_at, Timex.Ecto.DateTime
    field :override_xp, :integer

    belongs_to :mission, Mission
    belongs_to :student, User
    belongs_to :grader, User
    has_many :answers, Answer
=======
    field(:status, SubmissionStatus, default: :attempting)
    field(:submitted_at, Timex.Ecto.DateTime)
    field(:override_xp, :integer)

    belongs_to(:mission, Mission)
    belongs_to(:student, User)
    belongs_to(:grader, User)
    has_many(:answers, Answer)
>>>>>>> d08d50a55138354557a30d45d5423d8531f5c5b1

    timestamps()
  end

  @required_fields ~w(status)a
  @optional_fields ~w(override_xp submitted_at)a

  def changeset(submission, params) do
<<<<<<< HEAD
    params = convert_date(params, "submitted_at")
=======
    params = convert_date(params, :submitted_at)

>>>>>>> d08d50a55138354557a30d45d5423d8531f5c5b1
    submission
    |> cast(params, @required_fields ++ @optional_fields)
    |> validate_required(@required_fields)
    |> validate_role(:student, "student")
    |> validate_role(:grader, "staff")
  end

  def validate_role(changeset, user, role) do
    validate_change(changeset, user, fn ^user, user ->
<<<<<<< HEAD
      case user.role == ^role do
        true -> []
        false -> [{^user, "Access Denied"}]
      end
    end)
  end

=======
      case user.role == role do
        true -> []
        false -> [{user, "Access Denied"}]
      end
    end)
  end
>>>>>>> d08d50a55138354557a30d45d5423d8531f5c5b1
end
