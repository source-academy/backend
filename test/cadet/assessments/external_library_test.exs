defmodule Cadet.Assessments.Library.ExternalLibraryTest do
  alias Cadet.Assessments.Library.ExternalLibrary

  use Cadet.ChangesetCase, entity: ExternalLibrary

  describe "Changesets" do
    setup do
      %{valid_params: build(:external_library)}
    end

    test "valid changesets", %{valid_params: params} do
      assert_changeset(params, :valid)
    end
  end
end
