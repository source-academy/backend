defmodule Cadet.Assessments.Version do
  @moduledoc """
  Versions model contains domain logic for versions management for
  programming and multiple choice questions.
  """
  use Ecto.Schema
  import Ecto.Changeset

  alias Cadet.Assessments.Answer

  schema "versions" do
    field(:content, :map)
    field(:name, :string)

    belongs_to(:answer, Answer)

    timestamps()
  end

  @doc false
  def changeset(version, attrs) do
    version
    |> cast(attrs, [:content, :name, :answer_id])
    |> validate_required([:content, :answer_id])
    |> foreign_key_constraint(:answer_id)
  end
end
