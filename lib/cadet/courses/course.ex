defmodule Cadet.Courses.Course do
  @moduledoc """
  The Course entity stores the configuration of a particular course.
  """
  use Cadet, :model

  alias Cadet.Courses.AssessmentConfig

  @type t :: %__MODULE__{
          course_name: String.t(),
          course_short_name: String.t(),
          viewable: boolean(),
          enable_game: boolean(),
          enable_achievements: boolean(),
          enable_sourcecast: boolean(),
          enable_stories: boolean(),
          enable_llm_grading: boolean(),
          source_chapter: integer(),
          source_variant: String.t(),
          module_help_text: String.t(),
          assets_prefix: String.t() | nil
        }

  schema "courses" do
    field(:course_name, :string)
    field(:course_short_name, :string)
    field(:viewable, :boolean, default: true)
    field(:enable_game, :boolean, default: true)
    field(:enable_achievements, :boolean, default: true)
    field(:enable_sourcecast, :boolean, default: true)
    field(:enable_stories, :boolean, default: false)
    field(:enable_llm_grading, :boolean)
    field(:source_chapter, :integer)
    field(:source_variant, :string)
    field(:module_help_text, :string)

    # for now, only settable from database
    field(:assets_prefix, :string, default: nil)

    has_many(:assessment_config, AssessmentConfig)

    timestamps()
  end

  @required_fields ~w(course_name viewable enable_game
    enable_achievements enable_sourcecast enable_stories source_chapter source_variant)a
  @optional_fields ~w(course_short_name module_help_text enable_llm_grading)a

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
    case {chap, var} do
      {true, true} ->
        case get_field(changeset, :source_chapter) do
          1 ->
            validate_inclusion(changeset, :source_variant, [
              "default",
              "lazy",
              "wasm",
              "native",
              "typed"
            ])

          2 ->
            validate_inclusion(changeset, :source_variant, ["default", "lazy", "native", "typed"])

          3 ->
            validate_inclusion(changeset, :source_variant, [
              "default",
              "concurrent",
              "non-det",
              "native",
              "typed"
            ])

          4 ->
            validate_inclusion(changeset, :source_variant, ["default", "gpu", "native"])

          _ ->
            add_error(changeset, :source_chapter, "is invalid")
        end

      {false, false} ->
        changeset

      {_, _} ->
        add_error(
          changeset,
          :source_chapter,
          "source chapter and source variant must be present together"
        )
    end
  end
end
