defmodule Cadet.AssessmentsTest do
  use Cadet.DataCase

  alias Cadet.Assessments

  test "create mission" do
    {:ok, mission} =
      Assessments.create_mission(%{
        title: "mission",
        category: :mission,
        open_at: Timex.now,
        close_at: Timex.shift(Timex.now, days: 7),
        is_published: false
      })

    assert mission.title == "mission"
    assert mission.category == :mission
  end

  test "create sidequest" do
    {:ok, mission} =
      Assessments.create_mission(%{
        title: "sidequest",
        category: :sidequest,
        open_at: Timex.now,
        close_at: Timex.shift(Timex.now, days: 7),
        is_published: false
      })

    assert mission.title == "mission"
    assert mission.category == :sidequest
  end

  test "create contest" do
    {:ok, mission} =
      Assessments.create_mission(%{
        title: "contest",
        category: :contest,
        open_at: Timex.now,
        close_at: Timex.shift(Timex.now, days: 7),
        is_published: false
      })

    assert mission.title == "mission"
    assert mission.category == :contest
  end

  test "create path" do
    {:ok, mission} =
      Assessments.create_mission(%{
        title: "path",
        category: :path,
        open_at: Timex.now,
        close_at: Timex.shift(Timex.now, days: 7),
        is_published: false
      })

    assert mission.title == "mission"
    assert mission.category == :path
  end

  test "create programming question" do
    mission = Assessments.create_mission(%{
        title: "mission",
        category: :mission,
        open_at: Timex.now,
        close_at: Timex.shift(Timex.now, days: 7),
        is_published: false
      })
    {:ok, question} =
      Assessments.create_question(%{
        title: "question",
        weight: 5,
      }, :programming, mission.id)

    assert question.title == "question"
    assert question.type == :programming
    assert question.weight == 5
  end

  test "create multiple choice question" do
    mission = Assessments.create_mission(%{
        title: "mission",
        category: :mission,
        open_at: Timex.now,
        close_at: Timex.shift(Timex.now, days: 7),
        is_published: false
      })
    {:ok, question} =
      Assessments.create_question(%{
        title: "question",
        weight: 5,
      }, :multiple, mission.id)

    assert question.title == "question"
    assert question.type == :multiple_choice
    assert question.weight == 5
  end

  test "publish mission" do
    mission = Assessments.create_mission(%{
        title: "mission",
        category: :mission,
        open_at: Timex.now,
        close_At: Timex.shift(Timex.now, days: 7),
        is_published: false
      })
    {:ok, mission} = Assessments.publish_mission(mission.id)
    assert mission.is_published == true
  end
end
