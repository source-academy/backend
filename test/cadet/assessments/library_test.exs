defmodule Cadet.Assessments.LibraryTest do
  alias Cadet.Assessments.Library

  use Cadet.ChangesetCase, entity: Library

  describe "Changesets" do
    setup do
      %{valid_params: build(:library)}
    end

    test "valid changesets", %{valid_params: params} do
      assert_changeset(params, :valid)
    end

    test "invalid changeset invalid globals", %{valid_params: params} do
      invalid_globals = [
        %{"foo" => ["foo", "bar"]},
        %{"foo" => %{"foo" => "bar"}}
      ]

      for global <- invalid_globals do
        params
        |> Map.put(:globals, global)
        |> assert_changeset(:invalid)
      end
    end

    test "invalid changeset invalid chapter", %{valid_params: params} do
      params
      |> Map.put(:chapter, 100)
      |> assert_changeset(:invalid)

      params
      |> Map.put(:chapter, 0)
      |> assert_changeset(:invalid)
    end

    test "valid changeset valid chapter-variant", %{valid_params: params} do
      variants = [
        {1, "default"},
        {1, "wasm"},
        {1, "lazy"},
        {1, "native"},
        {1, "typed"},
        {2, "default"},
        {2, "lazy"},
        {2, "native"},
        {2, "typed"},
        {3, "default"},
        {3, "concurrent"},
        {3, "non-det"},
        {3, "native"},
        {3, "typed"},
        {4, "default"},
        {4, "gpu"},
        {4, "native"}
      ]

      for {c, v} <- variants do
        params
        |> Map.merge(%{chapter: c, variant: v})
        |> assert_changeset(:valid)
      end

      # no variant
      params
      |> Map.merge(%{chapter: 1})
      |> assert_changeset(:valid)
    end

    test "valid changeset invalid chapter-variant", %{valid_params: params} do
      variants = [
        {1, "hello"},
        {1, "concurrent"},
        {1, "non-det"},
        {2, "undefault"},
        {2, "eager"},
        {3, "concurren"},
        {4, "geforce rtx 3080"}
      ]

      for {c, v} <- variants do
        params
        |> Map.merge(%{chapter: c, variant: v})
        |> assert_changeset(:invalid)
      end
    end

    test "invalid changeset empty" do
      refute (%Library{chapter: nil}
              |> Library.changeset(%{})).valid?
    end

    test "valid changeset without globals", %{valid_params: params} do
      params
      |> Map.delete(:globals)
      |> assert_changeset(:valid)
    end

    test "empty external valid changeset", %{valid_params: params} do
      params
      |> Map.delete(:external)
      |> assert_changeset(:valid)
    end
  end
end
