defmodule Cadet.Course.CategoryTest do
  alias Cadet.Course.Category

  use Cadet.ChangesetCase, entity: Category

  describe "Changesets" do
    test "valid changesets" do
      assert_changeset(
        %{
          title: "Category",
          description: "Some description"
        },
        :valid
      )
    end

    test "invalid changeset" do
      assert_changeset(%{title: "", description: "some description"}, :invalid)
    end
  end
end
