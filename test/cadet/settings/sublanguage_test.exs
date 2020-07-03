defmodule Cadet.Settings.SublanguageTest do
  alias Cadet.Settings.Sublanguage

  use Cadet.ChangesetCase, entity: Sublanguage

  describe "Changesets" do
    test "valid changeset" do
      assert_changeset(
        %{
          chapter: 4,
          variant: "gpu"
        },
        :valid
      )
    end

    test "invalid changeset for chapter number" do
      assert_changeset(
        %{
          chapter: 5,
          variant: "default"
        },
        :invalid
      )
    end

    test "invalid changeset for variant" do
      assert_changeset(
        %{
          chapterno: 1,
          variant: "wrong variant"
        },
        :invalid
      )
    end
  end
end
