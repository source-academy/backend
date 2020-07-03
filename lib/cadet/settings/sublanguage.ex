defmodule Cadet.Settings.Sublanguage do
  @moduledoc """
  The Sublanguage entity stores the chapter and variant of the default
  sublanguage in use by the Playground.
  """
  use Cadet, :model
  use Arc.Ecto.Schema

  schema "sublanguages" do
    field(:chapter, :integer)
    field(:variant, :string)
  end

  @required_fields ~w(chapter variant)a

  def changeset(sublanguage, params) do
    sublanguage
    |> cast(params, @required_fields)
    |> validate_inclusion(:chapter, 1..4)
    |> validate_inclusion(:variant, ["default", "concurrent", "gpu", "lazy", "non-det", "wasm"])
  end
end
