defmodule Cadet.Incentives.AchievementsTest do
  use Cadet.DataCase

  alias Cadet.Incentives.{
    Achievement,
    AchievementPrerequisite,
    Achievements,
    AchievementToGoal
  }

  alias Ecto.UUID

  import Cadet.TestEntityHelper

  test "create achievements" do
    course = insert(:course)

    {:ok, %{uuid: uuid}} =
      Achievements.upsert(%{
        uuid: Ecto.UUID.generate(),
        course_id: course.id,
        title: "test achievement",
        is_task: false,
        position: 0,
        xp: 0,
        is_variable_xp: false
      })

    assert %{title: "test achievement"} = Repo.get(Achievement, uuid)
  end

  test "create achievement with prerequisites as id" do
    course = insert(:course)
    a1 = insert(:achievement, %{course: course})
    a2 = insert(:achievement, %{course: course})
    prerequisite_uuids = [a1.uuid, a2.uuid]
    a_uuid = UUID.generate()
    attrs = achievement_literal(0)

    {:ok, _} =
      attrs
      |> Map.merge(%{
        course_id: course.id,
        uuid: a_uuid,
        prerequisite_uuids: prerequisite_uuids
      })
      |> Achievements.upsert()

    assert Enum.sort(get_prerequisites(a_uuid)) == Enum.sort(prerequisite_uuids)
  end

  test "create achievement with goals as id" do
    g = insert(:goal)
    a_uuid = UUID.generate()
    attrs = achievement_literal(0)

    {:ok, _} =
      attrs
      |> Map.merge(%{
        course_id: g.course_id,
        uuid: a_uuid,
        goal_uuids: [g.uuid]
      })
      |> Achievements.upsert()

    assert Enum.sort(get_goals(a_uuid)) == [g.uuid]
  end

  test "get achievements" do
    course = insert(:course)
    goal = insert(:goal, %{course: course})
    prereq = insert(:achievement, %{course: course})
    achievement = insert(:achievement, Map.merge(achievement_literal(0), %{course: course}))

    Repo.insert(%AchievementPrerequisite{
      prerequisite_uuid: prereq.uuid,
      achievement_uuid: achievement.uuid
    })

    Repo.insert(%AchievementToGoal{
      achievement_uuid: achievement.uuid,
      goal_uuid: goal.uuid
    })

    goal_uuid = goal.uuid
    prereq_uuid = prereq.uuid
    achievement = Enum.find(Achievements.get(course.id), &(&1.uuid == achievement.uuid))

    assert achievement_literal(0) = achievement
    assert [%{goal_uuid: ^goal_uuid}] = achievement.goals
    assert [%{prerequisite_uuid: ^prereq_uuid}] = achievement.prerequisites
  end

  test "update achievements" do
    new_title = "New String"
    achievement = insert(:achievement, achievement_literal(0))

    assert {:ok, _} =
             Achievements.upsert(%{
               uuid: achievement.uuid,
               title: new_title
             })

    assert %{title: ^new_title} = Repo.get(Achievement, achievement.uuid)
  end

  test "update prerequisites" do
    a = insert(:achievement, achievement_literal(0))
    p1 = insert(:achievement, achievement_literal(1))
    p2 = insert(:achievement, achievement_literal(2))

    test_change_prerequisites(a.uuid, [])
    test_change_prerequisites(a.uuid, [p1.uuid, p2.uuid])
    test_change_prerequisites(a.uuid, [p1.uuid])
    test_change_prerequisites(a.uuid, [p2.uuid])
    test_change_prerequisites(a.uuid, [])
  end

  test "update goals" do
    a = insert(:achievement, achievement_literal(0))
    g1 = insert(:goal)
    g2 = insert(:goal)

    test_change_goals(a.uuid, [])
    test_change_goals(a.uuid, [g1.uuid, g2.uuid])
    test_change_goals(a.uuid, [g1.uuid])
    test_change_goals(a.uuid, [g2.uuid])
    test_change_goals(a.uuid, [])
  end

  test "bulk insert succeeds" do
    course = insert(:course)

    attrs =
      [achievement_literal(0), achievement_literal(1)]
      |> Enum.map(&Map.merge(&1, %{course_id: course.id, uuid: UUID.generate()}))

    assert {:ok, result} = Achievements.upsert_many(attrs)
    assert [achievement_literal(0), achievement_literal(1)] = result

    [%{uuid: uuid0}, %{uuid: uuid1}] = attrs
    assert achievement_literal(0) = Repo.get(Achievement, uuid0)
    assert achievement_literal(1) = Repo.get(Achievement, uuid1)
  end

  test "bulk insert is atomic" do
    attrs = [Map.merge(achievement_literal(0), %{uuid: UUID.generate()}), achievement_literal(1)]

    assert {:error, _} = Achievements.upsert_many(attrs)

    [%{uuid: uuid} | _] = attrs
    assert Achievement |> Repo.get(uuid) |> is_nil()
  end

  defp test_change_prerequisites(achievement_uuid, prerequisite_uuids) do
    assert {:ok, _} =
             Achievements.upsert(%{
               uuid: achievement_uuid,
               prerequisite_uuids: prerequisite_uuids
             })

    assert get_prerequisites(achievement_uuid) == Enum.sort(prerequisite_uuids)
  end

  defp test_change_goals(achievement_uuid, goal_uuids) do
    assert {:ok, _} =
             Achievements.upsert(%{
               uuid: achievement_uuid,
               goal_uuids: goal_uuids
             })

    assert get_goals(achievement_uuid) == Enum.sort(goal_uuids)
  end

  defp get_prerequisites(achievement_uuid) do
    Achievement
    |> preload([:prerequisites])
    |> Repo.get(achievement_uuid)
    |> Map.fetch!(:prerequisites)
    |> Enum.map(& &1.prerequisite_uuid)
    |> Enum.sort()
  end

  defp get_goals(achievement_uuid) do
    Achievement
    |> preload([:goals])
    |> Repo.get(achievement_uuid)
    |> Map.fetch!(:goals)
    |> Enum.map(& &1.goal_uuid)
    |> Enum.sort()
  end

  test "delete achievement" do
    a = insert(:achievement, achievement_literal(0))
    assert :ok = Achievements.delete(a.uuid)
    assert Achievement |> Repo.get(a.uuid) |> is_nil()
  end
end
