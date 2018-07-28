defmodule Cadet.Assessments.Library do
  @moduledoc """
  The library entity represents a library to be used in a  question.
  """
  use Cadet, :model

  alias Cadet.Assessments.Library.ExternalLibrary

  @primary_key false
  embedded_schema do
    field(:chapter, :integer, default: 1)
    field(:globals, :map, default: %{})
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
    |> validate_globals()
  end

  def validate_globals(changeset) do
    globals = get_change(changeset, :globals)

    with {:nil?, false} <- {:nil?, is_nil(globals)},
         {:valid?, true} <-
           {:valid?,
            Enum.all?(globals, fn {name, value} -> is_binary(name) and is_binary(value) end)} do
      changeset
    else
      {:nil?, true} -> changeset
      _ -> add_error(changeset, :globals, "invalid format")
    end
  end
end
