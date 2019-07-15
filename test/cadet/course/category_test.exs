defmodule Cadet.Course.CategoryTest do
  alias Cadet.Course.Category

  use Cadet.ChangesetCase, entity: Category

  describe "Changesets" do
    test "valid changesets" do
      assert_changeset(
        %{
          name: "Category",
          description: "Some description"
        },
        :valid
      )
    end

    test "invalid changeset" do
      assert_changeset(%{name: "", description: "some description"}, :invalid)
    end
  end
end
