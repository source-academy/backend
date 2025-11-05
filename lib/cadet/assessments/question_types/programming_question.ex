defmodule Cadet.Assessments.QuestionTypes.ProgrammingQuestion do
  @moduledoc """
  The ProgrammingQuestion entity represents a Programming question.
  """
  use Cadet, :model

  alias Cadet.Assessments.QuestionTypes.Testcase

  @primary_key false
  embedded_schema do
    field(:content, :string)
    field(:prepend, :string, default: "")
    field(:template, :string)
    field(:postpend, :string, default: "")
    field(:solution, :string)
    field(:llm_prompt, :string)
    embeds_many(:public, Testcase)
    embeds_many(:opaque, Testcase)
    embeds_many(:secret, Testcase)
  end

  @required_fields ~w(content template)a
  @optional_fields ~w(solution prepend postpend llm_prompt)a

  def changeset(question, params \\ %{}) do
    question
    |> cast(params, @required_fields ++ @optional_fields)
    |> cast_embed(:public, with: &Testcase.changeset/2)
    |> cast_embed(:opaque, with: &Testcase.changeset/2)
    |> cast_embed(:secret, with: &Testcase.changeset/2)
    |> validate_required(@required_fields)
  end
end
