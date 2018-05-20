defmodule Cadet.Assessments.Submission do
  @moduledoc false
  use Cadet, :model

  alias Cadet.Assessments.Assessment
  alias Cadet.Assessments.SubmissionStatus

  schema "submissions" do
    field :status, SubmissionStatus, default: :attempting
    field :submitted_at, Timex.Ecto.DateTime
    field :override_xp, :integer

    belongs_to :assessment, Assessment
    has_many :answers, Answer

    timestamps()
  end

  @required_fields ~w(status)a
  @optional_fields ~w(override_xp submitted_at)a

  def changeset(submission, params) do
    params = convert_date(params, "submitted_at")
    submission
    |> cast(params, @required_fields ++ @optional_fields)
    |> validate_required(@required_fields)
  end
end
