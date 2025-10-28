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
          enable_overall_leaderboard: boolean(),
          enable_contest_leaderboard: boolean(),
          top_leaderboard_display: integer(),
          top_contest_leaderboard_display: integer(),
          enable_sourcecast: boolean(),
          enable_stories: boolean(),
          enable_exam_mode: boolean(),
          resume_code: string(),
          is_official_course: boolean(),
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
    field(:enable_overall_leaderboard, :boolean, default: true)
    field(:enable_contest_leaderboard, :boolean, default: true)
    field(:top_leaderboard_display, :integer, default: 100)
    field(:top_contest_leaderboard_display, :integer, default: 10)
    field(:enable_sourcecast, :boolean, default: true)
    field(:enable_stories, :boolean, default: false)
    field(:enable_exam_mode, :boolean, default: false)
    field(:resume_code, :string)
    field(:is_official_course, :boolean, default: false)
    field(:source_chapter, :integer)
    field(:source_variant, :string)
    field(:module_help_text, :string)

    # for now, only settable from database
    field(:assets_prefix, :string, default: nil)

    has_many(:assessment_config, AssessmentConfig)

    timestamps()
  end

  @required_fields ~w(course_name viewable enable_game
    enable_exam_mode enable_achievements enable_overall_leaderboard enable_contest_leaderboard top_leaderboard_display top_contest_leaderboard_display enable_sourcecast enable_stories source_chapter source_variant)a
  @optional_fields ~w(course_short_name module_help_text resume_code)a

  def changeset(course, params) do
    course
    |> cast(params, @required_fields ++ @optional_fields)
    |> validate_required(@required_fields)
    |> validate_sublanguage_combination(params)
    |> validate_exam_mode(params)
  end

  # Validates combination of exam mode, resume code, and official course state
  defp validate_exam_mode(changeset, params) do
    has_resume_code = params |> Map.has_key?(:resume_code)

    resume_code_params =
      params
      |> Map.get(:resume_code, "")
      |> String.trim()

    resume_code =
      changeset
      |> get_field(:resume_code)

    enable_exam_mode = Map.get(params, :enable_exam_mode, false)
    is_official_course = get_field(changeset, :is_official_course, false)

    case {enable_exam_mode, is_official_course, has_resume_code, resume_code_params} do
      {_, _, true, ""} ->
        add_error(
          changeset,
          :resume_code,
          "Resume code must not be empty."
        )

      {true, false, _, _} ->
        add_error(
          changeset,
          :enable_exam_mode,
          "Exam mode is only available for official institution course."
        )

      _ ->
        changeset
    end
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
