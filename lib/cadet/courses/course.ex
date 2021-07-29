defmodule Cadet.Courses.Course do
  @moduledoc """
  The Course entity stores the configuration of a particular course.
  """
  use Cadet, :model

  alias Cadet.Courses.AssessmentConfig

  schema "courses" do
    field(:course_name, :string)
    field(:course_short_name, :string)
    field(:viewable, :boolean, default: true)
    field(:enable_game, :boolean, default: true)
    field(:enable_achievements, :boolean, default: true)
    field(:enable_sourcecast, :boolean, default: true)
    field(:source_chapter, :integer)
    field(:source_variant, :string)
    field(:module_help_text, :string)

    has_many(:assessment_config, AssessmentConfig)

    timestamps()
  end

  @required_fields ~w(course_name viewable enable_game
    enable_achievements enable_sourcecast source_chapter source_variant)a
  @optional_fields ~w(course_short_name module_help_text)a

  def changeset(course, params) do
    course
    |> cast(params, @required_fields ++ @optional_fields)
    |> validate_required(@required_fields)
    |> validate_sublanguage_combination(params)
  end

  # Validates combination of Source chapter and variant
  defp validate_sublanguage_combination(changeset, params) do
    chap = Map.has_key?(params, :source_chapter)
    var = Map.has_key?(params, :source_variant)

    # not (chap xor var)
    if (chap and var) or (not chap and not var) do
      case get_field(changeset, :source_chapter, nil) do
        nil -> changeset
        1 -> validate_inclusion(changeset, :source_variant, ["default", "lazy", "wasm"])
        2 -> validate_inclusion(changeset, :source_variant, ["default", "lazy"])
        3 -> validate_inclusion(changeset, :source_variant, ["default", "concurrent", "non-det"])
        4 -> validate_inclusion(changeset, :source_variant, ["default", "gpu"])
        _ -> add_error(changeset, :source_chapter, "is invalid")
      end
    else
      add_error(
        changeset,
        :source_chapter,
        "source chapter and source variant must be present together"
      )
    end
  end
end
