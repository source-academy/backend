defmodule Cadet.Incentives.GoalssTest do
  use Cadet.DataCase

  alias Cadet.Incentives.{Goal, GoalProgress, Goals}
  alias Ecto.UUID

  import Cadet.TestEntityHelper

  test "create goal" do
    course = insert(:course)
    uuid = UUID.generate()
    Goals.upsert(Map.merge(goal_literal(0), %{course_id: course.id, uuid: uuid}))
    assert goal_literal(0) = Repo.get(Goal, uuid)
  end

  test "get goals" do
    goal = insert(:goal, goal_literal(0))
    assert [goal_literal(0)] = Goals.get(goal.course_id)
  end

  test "get goals with progress" do
    course_reg = insert(:course_registration)

    goal =
      insert(:goal, Map.merge(goal_literal(0), %{course: nil, course_id: course_reg.course_id}))

    Repo.insert(%GoalProgress{
      count: 500,
      completed: false,
      course_reg_id: course_reg.id,
      goal_uuid: goal.uuid
    })

    retrieved_goal = Goals.get_with_progress(course_reg)

    assert [goal_literal(0)] = retrieved_goal
    assert [%{progress: [%{count: 500, completed: false}]}] = retrieved_goal
  end

  test "update goals" do
    new_text = "New String"
    goal = insert(:goal, goal_literal(0))

    assert {:ok, _} =
             Goals.upsert(%{
               uuid: goal.uuid,
               text: new_text,
               course_id: goal.course_id
             })

    assert %{text: ^new_text} = Repo.get(Goal, goal.uuid)
  end

  test "bulk insert succeeds" do
    course = insert(:course)

    attrs =
      [goal_literal(0), goal_literal(1)]
      |> Enum.map(&Map.merge(&1, %{course_id: course.id, uuid: UUID.generate()}))

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
    assert :ok = Goals.delete(g.uuid, g.course_id)
    assert Goal |> Repo.get(g.uuid) |> is_nil()
  end

  test "upsert progress" do
    goal = insert(:goal, goal_literal(0))
    course_reg = insert(:course_registration, %{course: goal.course})

    assert {:ok, _} =
             Goals.upsert_progress(
               %{
                 count: 100,
                 completed: false,
                 goal_uuid: goal.uuid,
                 course_reg_id: course_reg.id
               },
               goal.uuid,
               course_reg.id
             )

    retrieved_goal = Goals.get_with_progress(course_reg)
    assert [%{progress: [%{count: 100, completed: false}]}] = retrieved_goal

    assert {:ok, _} =
             Goals.upsert_progress(
               %{
                 count: 200,
                 completed: true,
                 goal_uuid: goal.uuid,
                 course_reg_id: course_reg.id
               },
               goal.uuid,
               course_reg.id
             )

    retrieved_goal = Goals.get_with_progress(course_reg)
    assert [%{progress: [%{count: 200, completed: true}]}] = retrieved_goal
  end
end
