defmodule Cadet.Accounts.CourseRegistrationTest do
  alias Cadet.Accounts.CourseRegistration

  use Cadet.ChangesetCase, entity: CourseRegistration

  setup do

  end

  # :TODO add context function test
  describe "Changesets" do
    test "valid changeset" do
      assert_changeset(%{user_id: , course_id: , role: :admin}, :valid)
      assert_changeset(%{user_id: , course_id: , role: :student}, :valid)
    end

    test "invalid changeset" do
      assert_changeset(%{name: "people"}, :invalid)
      assert_changeset(%{role: :avenger}, :invalid)
    end
  end
end
