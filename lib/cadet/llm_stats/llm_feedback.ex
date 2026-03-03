defmodule Cadet.LLMStats.LLMFeedback do
  @moduledoc """
  Schema for user feedback on the LLM "Generate Comments" feature.
  """

  use Ecto.Schema
  import Ecto.Changeset

  schema "llm_feedback" do
    belongs_to(:course, Cadet.Courses.Course)
    belongs_to(:assessment, Cadet.Assessments.Assessment)
    belongs_to(:question, Cadet.Assessments.Question)
    belongs_to(:user, Cadet.Accounts.User)

    field(:rating, :integer)
    field(:body, :string)

    timestamps()
  end

  @required_fields ~w(course_id user_id body)a
  @optional_fields ~w(assessment_id question_id rating)a

  def changeset(feedback, attrs) do
    feedback
    |> cast(attrs, @required_fields ++ @optional_fields)
    |> validate_required(@required_fields)
    |> validate_inclusion(:rating, 1..5)
    |> foreign_key_constraint(:course_id)
    |> foreign_key_constraint(:assessment_id)
    |> foreign_key_constraint(:question_id)
    |> foreign_key_constraint(:user_id)
  end
end
