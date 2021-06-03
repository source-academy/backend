defmodule Cadet.Courses.Course do
  @moduledoc """
  The Course entity stores the configuration of a particular course.
  """
  use Cadet, :model

  schema "courses" do
    field(:name, :string)
    field(:module_code, :string)
    field(:viewable, :boolean, default: true)
    field(:enable_game, :boolean, default: true)
    field(:enable_achievements, :boolean, default: true)
    field(:enable_sourcecast, :boolean, default: true)
    field(:source_chapter, :integer)
    field(:source_variant, :string)
    field(:module_help_text, :string)

    timestamps()
  end

  @required_fields_sublanguage ~w(source_chapter source_variant)a

  def sublanguage_changeset(course, params) do
    course
    |> cast(params, @required_fields_sublanguage)
    |> validate_required(@required_fields_sublanguage)
    |> validate_allowed_combination()
  end

  # Validates combination of Source chapter and variant
  defp validate_allowed_combination(changeset) do
    case get_field(changeset, :source_chapter) do
      1 -> validate_inclusion(changeset, :source_variant, ["default", "lazy", "wasm"])
      2 -> validate_inclusion(changeset, :source_variant, ["default", "lazy"])
      3 -> validate_inclusion(changeset, :source_variant, ["default", "concurrent", "non-det"])
      4 -> validate_inclusion(changeset, :source_variant, ["default", "gpu"])
      _ -> add_error(changeset, :source_chapter, "is invalid")
    end
  end
end
