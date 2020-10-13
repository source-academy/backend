defmodule Cadet.Assessments.Library.ExternalLibrary do
  @moduledoc """
  The library entity represents an external library to be used in a  question.
  """
  use Cadet, :model

  @primary_key false
  embedded_schema do
    field(:name, :string, default: "none")
    field(:symbols, {:array, :string}, default: [])
  end

  @required_fields ~w(name symbols)a

  def changeset(library, params \\ %{}) do
    library
    |> cast(params, @required_fields)
    |> validate_required(@required_fields)
  end
end
