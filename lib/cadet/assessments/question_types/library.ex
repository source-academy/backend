defmodule Cadet.Assessments.QuestionTypes.Library do
  @moduledoc """
  The library entity represents a library to be used in a programming question.
  """
  use Cadet, :model

  embedded_schema do
    field(:version, :integer, default: 1)
    field(:globals, {:array, :string}, default: [])
    field(:externals, {:array, :string}, default: [])
    field(:files, {:array, :string}, default: [])
  end

  @required_fields ~w(version)a
  @optional_fields ~w(globals externals files)a

  def changeset(library, params \\ %{}) do
    library
    |> cast(params, @required_fields ++ @optional_fields)
    |> validate_required(@required_fields)
  end
end
