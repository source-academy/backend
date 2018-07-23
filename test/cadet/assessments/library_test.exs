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

    test "invalid changeset missing external library field", %{valid_params: params} do
      params
      |> Map.delete(:external)
      |> assert_changeset(:invalid)
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
  end
end
