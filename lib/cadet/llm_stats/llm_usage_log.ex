defmodule Cadet.LLMStats.LLMUsageLog do
  @moduledoc """
  Schema for logging each usage of the LLM "Generate Comments" feature.
  """

  use Ecto.Schema
  import Ecto.Changeset

  schema "llm_usage_logs" do
    belongs_to(:course, Cadet.Courses.Course)
    belongs_to(:assessment, Cadet.Assessments.Assessment)
    belongs_to(:question, Cadet.Assessments.Question)
    belongs_to(:answer, Cadet.Assessments.Answer)
    belongs_to(:submission, Cadet.Assessments.Submission)
    belongs_to(:user, Cadet.Accounts.User)

    timestamps()
  end

  @required_fields ~w(course_id assessment_id question_id answer_id submission_id user_id)a

  def changeset(log, attrs) do
    log
    |> cast(attrs, @required_fields)
    |> validate_required(@required_fields)
    |> foreign_key_constraint(:course_id)
    |> foreign_key_constraint(:assessment_id)
    |> foreign_key_constraint(:question_id)
    |> foreign_key_constraint(:answer_id)
    |> foreign_key_constraint(:submission_id)
    |> foreign_key_constraint(:user_id)
  end
end
