defmodule Cadet.Courses.Course do
  @moduledoc """
  The Course entity stores the configuration of a particular course.
  """
  use Cadet, :model

  alias Cadet.Courses.AssessmentConfig
  alias CadetWeb.AICommentsHelpers

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
          enable_llm_grading: boolean(),
          llm_api_key: String.t() | nil,
          llm_model: String.t() | nil,
          llm_api_url: String.t() | nil,
          llm_course_level_prompt: String.t() | nil,
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
    field(:enable_llm_grading, :boolean, default: false)
    field(:llm_api_key, :string, default: nil)
    field(:llm_model, :string, default: nil)
    field(:llm_api_url, :string, default: nil)
    field(:llm_course_level_prompt, :string, default: nil)
    field(:source_chapter, :integer)
    field(:source_variant, :string)
    field(:module_help_text, :string)

    # for now, only settable from database
    field(:assets_prefix, :string, default: nil)

    has_many(:assessment_config, AssessmentConfig)

    timestamps()
  end

  @required_fields ~w(course_name viewable enable_game
    enable_achievements enable_overall_leaderboard enable_contest_leaderboard top_leaderboard_display top_contest_leaderboard_display enable_sourcecast enable_stories source_chapter source_variant)a
  @optional_fields ~w(course_short_name module_help_text enable_llm_grading llm_api_key llm_model llm_api_url llm_course_level_prompt)a

  def changeset(course, params) do
    course
    |> cast(params, @required_fields ++ @optional_fields)
    |> validate_required(@required_fields)
    |> validate_sublanguage_combination(params)
    |> put_encrypted_llm_api_key()
  end

  def put_encrypted_llm_api_key(changeset) do
    if llm_api_key = get_change(changeset, :llm_api_key) do
      if is_binary(llm_api_key) and llm_api_key != "" do
        encrypted = AICommentsHelpers.encrypt_llm_api_key(llm_api_key)

        case encrypted do
          {:error, :invalid_encryption_key} ->
            add_error(
              changeset,
              :llm_api_key,
              "encryption key is not configured properly, cannot store LLM API key"
            )

          encrypted ->
            put_change(changeset, :llm_api_key, encrypted)
        end
      else
        # If empty string or nil is provided, don't encrypt but don't add error
        changeset
      end
    else
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
