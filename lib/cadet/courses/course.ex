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

  @optional_fields ~w(name source_chapter source_variant module_code viewable enable_game
    enable_achievements enable_sourcecast module_help_text)a

  def changeset(course, params) do
    course
    |> cast(params, @optional_fields)
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
