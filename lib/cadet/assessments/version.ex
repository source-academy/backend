defmodule Cadet.Assessments.Version do
  use Ecto.Schema
  import Ecto.Changeset

  alias Cadet.Assessments.Answer

  schema "versions" do
    field(:version, :map)
    field(:name, :string)
    field(:restored, :boolean, default: false)
    field(:restored_from, :id)

    belongs_to(:answer, Answer)

    timestamps()
  end

  @doc false
  def changeset(version, attrs) do
    version
    |> cast(attrs, [:version, :name, :restored])
    |> validate_required([:version, :restored])
  end
end
