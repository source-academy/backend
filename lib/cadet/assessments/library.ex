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
    embeds_one(:external, ExternalLibrary, on_replace: :update)
  end

  @required_fields ~w(chapter)a
  @optional_fields ~w(globals)a
  @required_embeds ~w(external)a

  def changeset(library, params \\ %{}) do
    library
    |> cast(params, @required_fields ++ @optional_fields)
    |> cast_embed(:external)
    |> put_default_external()
    |> validate_required(@required_fields ++ @required_embeds)
    |> validate_globals()
  end

  defp validate_globals(changeset) do
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

  def put_default_external(changeset) do
    external = get_change(changeset, :external)

    if external do
      changeset
    else
      put_change(changeset, :external, %ExternalLibrary{})
    end
  end
end
