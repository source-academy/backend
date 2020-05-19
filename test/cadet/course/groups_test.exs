defmodule Cadet.Course.GroupsTest do
  use Cadet.DataCase

  alias Cadet.{Accounts, Accounts.User}
  alias Cadet.Course

  test "get group overviews" do
    group = insert(:group)
    {:ok, result} = Course.get_group_overviews(%User{role: :staff})
    avenger_name = Accounts.get_user(group.leader_id).name
    group_name = group.name
    group_id = group.id
    assert result == [%{id: group_id, avenger_name: avenger_name, name: group_name}]
  end
end
