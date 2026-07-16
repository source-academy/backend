defmodule Cadet.Assessments.Library do
  @moduledoc """
  The library entity represents a library to be used in a question.

  Two formats are supported, distinguished by the `format` field:

    * `:legacy` (default) — the original Source-dialect library specified
      via `chapter` (from `@interpreter`), `variant`, `exec_time_ms`,
      `globals`, `language_options` and an embedded `external` library.

    * `:conductor` — a language-agnostic tuple of `(language, evaluator)`
      string IDs that are resolved by an external runtime. Legacy fields
      must NOT be present.

  See `Cadet.Updater.XMLParser` for the XML rule that determines which
  format a given `PROGRAMMINGLANGUAGE` element produces.
  """
  use Cadet, :model

  alias Cadet.Assessments.Library.ExternalLibrary

  @primary_key false
  embedded_schema do
    field(:format, Ecto.Enum, values: [:legacy, :conductor], default: :legacy)
    field(:chapter, :integer, default: 1)
    field(:variant, :string, default: nil)
    field(:exec_time_ms, :integer, default: 1000)
    field(:globals, :map, default: %{})
    field(:language_options, :map, default: %{})
    field(:language, :string, default: nil)
    field(:evaluator, :string, default: nil)
    embeds_one(:external, ExternalLibrary, on_replace: :update)
  end

  @required_fields ~w()a
  @optional_fields ~w(format globals variant language_options exec_time_ms language evaluator chapter)a

  def changeset(library, params \\ %{}) do
    library
    |> cast(params, @required_fields ++ @optional_fields)
    |> cast_embed(:external)
    |> put_default_external()
    |> validate_library_format()
    |> validate_globals()
    |> validate_chapter()
    |> validate_chapter_variant()
  end

  defp validate_library_format(changeset) do
    format = get_field(changeset, :format)

    case format do
      :conductor ->
        validate_conductor_format(changeset)

      _ ->
        validate_legacy_format(changeset)
    end
  end

  defp validate_conductor_format(changeset) do
    changeset
    |> validate_required([:language, :evaluator])
    |> validate_conductor_no_legacy_fields()
  end

  defp validate_conductor_no_legacy_fields(changeset) do
    forbidden = [:chapter, :variant, :exec_time_ms, :globals, :language_options]

    forbidden
    |> Enum.reduce(changeset, fn field, acc ->
      case fetch_change(acc, field) do
        {:ok, _value} ->
          add_error(acc, field, "must not be set for conductor format")

        :error ->
          acc
      end
    end)
    |> validate_conductor_no_external()
  end

  defp validate_conductor_no_external(changeset) do
    case fetch_change(changeset, :external) do
      {:ok, %ExternalLibrary{name: "none", symbols: []}} ->
        changeset

      {:ok, _} ->
        add_error(changeset, :external, "must not be set for conductor format")

      :error ->
        changeset
    end
  end

  defp validate_legacy_format(changeset) do
    changeset
    |> forbid_conductor_field(:language)
    |> forbid_conductor_field(:evaluator)
    |> validate_required([:chapter, :external])
  end

  defp forbid_conductor_field(changeset, field) do
    case fetch_change(changeset, field) do
      {:ok, value} when not is_nil(value) ->
        add_error(changeset, field, "must not be set for legacy format")

      _ ->
        changeset
    end
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

  defp validate_chapter(changeset) do
    if get_field(changeset, :format) == :conductor do
      changeset
    else
      case changeset |> fetch_change(:chapter) do
        {:ok, c} when c in 1..4 -> changeset
        :error -> changeset
        _ -> add_error(changeset, :chapter, "invalid chapter")
      end
    end
  end

  @valid_chapter_variants [
    {1, "typed"},
    {1, "wasm"},
    {1, "lazy"},
    {1, "native"},
    {2, "typed"},
    {2, "lazy"},
    {2, "native"},
    {3, "typed"},
    {3, "concurrent"},
    {3, "non-det"},
    {3, "native"},
    {4, "gpu"},
    {4, "native"}
  ]

  defp validate_chapter_variant(changeset) do
    if get_field(changeset, :format) == :conductor do
      changeset
    else
      do_validate_chapter_variant(changeset)
    end
  end

  defp do_validate_chapter_variant(changeset) do
    chapter = changeset |> fetch_field(:chapter)
    variant = changeset |> fetch_field(:variant)

    case {chapter, variant} do
      # no changes
      {{:data, _}, {:data, _}} ->
        changeset

      # default variant
      {{_, _c}, {_, v}} when is_nil(v) or v == "default" ->
        changeset

      {{_, chapter}, {_, variant}} ->
        if {chapter, variant} in @valid_chapter_variants do
          changeset
        else
          add_error(changeset, :variant, "invalid variant for given chapter")
        end
    end
  end

  def put_default_external(changeset) do
    format = get_field(changeset, :format)
    external = get_change(changeset, :external)

    cond do
      format == :conductor and is_nil(external) ->
        changeset

      external ->
        changeset

      true ->
        put_change(changeset, :external, %{})
    end
  end
end
