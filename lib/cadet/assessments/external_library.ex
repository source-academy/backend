defmodule Cadet.Assessments.Library.ExternalLibrary do
  @moduledoc """
  The library entity represents an external library to be used in a  question.
  """
  use Cadet, :model

  alias Cadet.Assessments.Library.ExternalLibraryName

  embedded_schema do
    field(:name, ExternalLibraryName, default: :none)
    field(:exposed_symbols, {:array, :string}, default: [])
  end

  @required_fields ~w(name exposed_symbols)a

  def changeset(library, params \\ %{}) do
    library
    |> cast(params, @required_fields)
    |> validate_required(@required_fields)
  end
end
