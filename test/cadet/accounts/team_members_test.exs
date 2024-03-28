defmodule Cadet.Accounts.TeamMemberTest do
  use Cadet.DataCase, async: true

  alias Cadet.Accounts.TeamMember
  alias Cadet.Repo

  @valid_attrs %{student_id: 1, team_id: 1}

  describe "changeset/2" do
    test "creates a valid changeset with valid attributes" do
      team_member = %TeamMember{}
      changeset = TeamMember.changeset(team_member, @valid_attrs)
      assert changeset.valid?
    end

    test "returns an error when required fields are missing" do
      team_member = %TeamMember{}
      changeset = TeamMember.changeset(team_member, %{})
      refute changeset.valid?
      assert {:error, _changeset} = Repo.insert(changeset)
    end

    test "returns an error when the team_id foreign key constraint is violated" do
      team_member = %TeamMember{}
      changeset = TeamMember.changeset(team_member, %{student_id: 1})
      refute changeset.valid?
      assert {:error, _changeset} = Repo.insert(changeset)
    end

    test "returns an error when the student_id foreign key constraint is violated" do
      team_member = %TeamMember{}
      changeset = TeamMember.changeset(team_member, %{team_id: 1})
      refute changeset.valid?
      assert {:error, _changeset} = Repo.insert(changeset)
    end
  end
end
