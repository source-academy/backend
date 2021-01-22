defmodule Cadet.Incentives.GoalssTest do
  use Cadet.DataCase

  alias Cadet.Incentives.{Goal, GoalProgress, Goals}
  alias Ecto.UUID

  import Cadet.TestEntityHelper

  test "create goal" do
    uuid = UUID.generate()
    Goals.upsert(Map.merge(goal_literal(0), %{uuid: uuid}))
    assert goal_literal(0) = Repo.get(Goal, uuid)
  end

  test "get goals" do
    insert(:goal, goal_literal(0))
    assert [goal_literal(0)] = Goals.get()
  end

  test "get goals with progress" do
    goal = insert(:goal, goal_literal(0))
    user = insert(:user)

    Repo.insert(%GoalProgress{
      xp: 500,
      completed: false,
      user_id: user.id,
      goal_uuid: goal.uuid
    })

    retrieved_goal = Goals.get_with_progress(user)

    assert [goal_literal(0)] = retrieved_goal
    assert [%{progress: [%{xp: 500, completed: false}]}] = retrieved_goal
  end

  test "update goals" do
    new_text = "New String"
    goal = insert(:goal, goal_literal(0))

    assert {:ok, _} =
             Goals.upsert(%{
               uuid: goal.uuid,
               text: new_text
             })

    assert %{text: ^new_text} = Repo.get(Goal, goal.uuid)
  end

  test "bulk insert succeeds" do
    attrs =
      [goal_literal(0), goal_literal(1)] |> Enum.map(&Map.merge(&1, %{uuid: UUID.generate()}))

    assert {:ok, result} = Goals.upsert_many(attrs)
    assert [goal_literal(0), goal_literal(1)] = result

    [%{uuid: uuid0}, %{uuid: uuid1}] = attrs
    assert goal_literal(0) = Repo.get(Goal, uuid0)
    assert goal_literal(1) = Repo.get(Goal, uuid1)
  end

  test "bulk insert is atomic" do
    attrs = [Map.merge(goal_literal(0), %{uuid: UUID.generate()}), goal_literal(1)]

    assert {:error, _} = Goals.upsert_many(attrs)

    [%{uuid: uuid} | _] = attrs
    assert Goal |> Repo.get(uuid) |> is_nil()
  end

  test "delete goal" do
    g = insert(:goal)
    assert :ok = Goals.delete(g.uuid)
    assert Goal |> Repo.get(g.uuid) |> is_nil()
  end
end
