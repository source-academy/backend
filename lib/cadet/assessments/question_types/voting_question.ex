defmodule Cadet.Assessments.QuestionTypes.VotingQuestion do
  @moduledoc """
  The VotingQuestion entity represents a Voting question.
  """
  use Cadet, :model
  alias Cadet.Assessments.QuestionTypes.ContestEntry

  @primary_key false
  embedded_schema do
    embeds_many(:contest_entries, ContestEntry)
    field(:content, :string)
    field(:prepend, :string, default: "")
    field(:template, :string)
    field(:postpend, :string, default: "")
  end

  @required_fields ~w(content)a
  @optional_fields ~w(prepend postpend template)a

  def changeset(question, params \\ %{}) do
    question
    |> cast(params, @required_fields ++ @optional_fields)
    |> validate_required(@required_fields)
  end
end
