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
    field(:restored, :boolean, default: false)
    field(:restored_from, :id)

    belongs_to(:answer, Answer)

    timestamps()
  end

  @doc false
  def changeset(version, attrs) do
    version
    |> cast(attrs, [:content, :name, :restored, :answer_id])
    |> validate_required([:content, :restored, :answer_id])
    |> foreign_key_constraint(:answer_id)
  end
end
