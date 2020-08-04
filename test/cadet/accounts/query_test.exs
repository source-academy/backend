defmodule Cadet.Accounts.QueryTest do
  use Cadet.DataCase

  alias Cadet.Accounts.Query

  test "all_students" do
    insert(:student)

    result = Query.all_students()

    assert 1 = Enum.count(result)
  end
end
