defmodule Cadet.Assessments.Library do
  @moduledoc """
  The library entity represents a library to be used in a  question.
  """
  use Cadet, :model

  alias Cadet.Assessments.Library.ExternalLibrary

  embedded_schema do
    field(:chapter, :integer, default: 1)
    field(:globals, {:array, :string}, default: [])
    embeds_one(:external, ExternalLibrary)
  end

  @required_fields ~w(chapter)a
  @optional_fields ~w(globals)a
  @required_embeds ~w(external)a

  def changeset(library, params \\ %{}) do
    library
    |> cast(params, @required_fields ++ @optional_fields)
    |> cast_embed(:external)
    |> validate_required(@required_fields ++ @required_embeds)
  end
end
