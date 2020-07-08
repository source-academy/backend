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
    |> validate_required(@required_fields)
    |> validate_allowed_combination()
  end

  defp validate_allowed_combination(changeset) do
    case get_field(changeset, :chapter) do
      1 -> validate_inclusion(changeset, :variant, ["default", "lazy", "wasm"])
      2 -> validate_inclusion(changeset, :variant, ["default", "lazy"])
      3 -> validate_inclusion(changeset, :variant, ["default", "concurrent", "non-det"])
      4 -> validate_inclusion(changeset, :variant, ["default", "gpu"])
      _ -> add_error(changeset, :chapter, "Invalid chapter number")
    end
  end
end
