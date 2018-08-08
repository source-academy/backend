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
