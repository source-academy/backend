defmodule Cadet.Assessments.Library do
  @moduledoc """
  The library entity represents a library to be used in a question.
  """
  use Cadet, :model

  alias Cadet.Assessments.Library.ExternalLibrary

  @primary_key false
  embedded_schema do
    field(:chapter, :integer, default: 1)
    field(:variant, :string, default: nil)
    field(:exec_time_ms, :integer, default: 1000)
    field(:globals, :map, default: %{})
    field(:language_options, :map, default: %{})
    field(:runtime, :string, default: "python")
    embeds_one(:external, ExternalLibrary, on_replace: :update)
  end

  @required_fields ~w(chapter)a
  @optional_fields ~w(globals variant language_options exec_time_ms runtime)a
  @required_embeds ~w(external)a

  def changeset(library, params \\ %{}) do
    library
    |> cast(params, @required_fields ++ @optional_fields)
    |> cast_embed(:external)
    |> put_default_external()
    |> validate_required(@required_fields ++ @required_embeds)
    |> validate_globals()
    |> validate_chapter()
    |> validate_chapter_variant()
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

  # With Conductor, the chapter of a library is the 1-based position of a language in the language
  # directory (python1 to python4 are 1 to 4, then python4Typed, and so on), not only a Source
  # chapter 1 to 4. The directory has about a dozen languages; the frontend checks the number
  # against the real list.
  @max_chapter 20

  defp validate_chapter(changeset) do
    case changeset |> fetch_change(:chapter) do
      {:ok, c} when c in 1..@max_chapter -> changeset
      :error -> changeset
      _ -> add_error(changeset, :chapter, "invalid chapter")
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
    external = get_change(changeset, :external)

    if external do
      changeset
    else
      put_change(changeset, :external, %{})
    end
  end
end
