defmodule Cadet.Assessments.QuestionTypes.Library do
  @moduledoc """
  The library entity represents a library to be used in a programming question.
  """
  use Ecto.Schema

  import Ecto.Changeset

  embedded_schema do
    field(:version, :integer)
    field(:globals, {:array, :string})
    field(:externals, {:array, :string})
    field(:files, {:array, :string})
  end

  @required_fields ~w(version)a
  @optional_fields ~w(globals externals files)a

  def changeset(library, params \\ %{}) do
    library
    |> cast(params, @required_fields ++ @optional_fields)
    |> validate_required(@required_fields)
  end
end
