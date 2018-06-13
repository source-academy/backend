defmodule Cadet.AssessmentsTest do
  use Cadet.DataCase

  alias Cadet.Assessments
  alias Cadet.Accounts

  test "all missions" do
    missions = [insert(:mission), insert(:mission), 
      insert(:mission), insert(:mission), insert(:mission)]
    result = Assessments.all_missions()
    assert Enum.all?(result, fn x -> x.id in Enum.map(missions,
      fn m -> m.id end) end)
  end

  test "all open missions" do
    open_mission = insert(:mission, is_published: true, category: :mission)
    closed_mission = insert(:mission, is_published: false, category: :mission)
    result = Assessments.all_open_missions(:mission)
    assert open_mission in result
    refute closed_mission in result
  end
  
  test "create mission" do
    {:ok, mission} =
      Assessments.create_mission(%{
        title: "mission",
        category: :mission,
        open_at: Timex.now(),
        close_at: Timex.shift(Timex.now(), days: 7)
      })

    assert mission.title == "mission"
    assert mission.category == :mission
  end

  test "create sidequest" do
    {:ok, mission} =
      Assessments.create_mission(%{
        title: "sidequest",
        category: :sidequest,
        open_at: Timex.now(),
        close_at: Timex.shift(Timex.now(), days: 7)
      })

    assert mission.title == "sidequest"
    assert mission.category == :sidequest
  end

  test "create contest" do
    {:ok, mission} =
      Assessments.create_mission(%{
        title: "contest",
        category: :contest,
        open_at: Timex.now(),
        close_at: Timex.shift(Timex.now(), days: 7)
      })

    assert mission.title == "contest"
    assert mission.category == :contest
  end

  test "create path" do
    {:ok, mission} =
      Assessments.create_mission(%{
        title: "path",
        category: :path,
        open_at: Timex.now(),
        close_at: Timex.shift(Timex.now(), days: 7)
      })

    assert mission.title == "path"
    assert mission.category == :path
  end

  test "create programming question" do
    mission = insert(:mission)
    {:ok, question} =
      Assessments.create_question(
        %{
          title: "question",
          weight: 5,
          type: :programming,
          question: %{},
          raw_question: "{\"content\": \"asd\", \"solution_template\": \"template\",
            \"solution\": \"soln\", \"library\": {\"version\": 1}}"
        },
        mission.id
      )

    assert question.title == "question"
    assert question.weight == 5
    assert question.type == :programming
  end

  test "create multiple choice question" do
    mission = insert(:mission)
    {:ok, question} =
      Assessments.create_question(
        %{
          title: "question",
          weight: 5,
          type: :multiple_choice,
          question: %{},
          raw_question: "{\"content\":\"asd\",\"choices\":[{\"is_correct\":true,\"content\":\"asd\"}]}"
        },
        mission.id
      )

    assert question.title == "question"
    assert question.weight == 5
    assert question.type == :multiple_choice
  end

  test "publish mission" do
    {:ok, mission} =
      Assessments.create_mission(%{
        title: "mission",
        category: :mission,
        open_at: Timex.now(),
        close_at: Timex.shift(Timex.now(), days: 7)
      })

    {:ok, mission} = Assessments.publish_mission(mission.id)
    assert mission.is_published == true
  end

  test "update mission" do
    {:ok, mission} =
      Assessments.create_mission(%{
        title: "mission",
        category: :mission,
        open_at: Timex.now(),
        close_at: Timex.shift(Timex.now(), days: 7)
      })

    Assessments.update_mission(mission.id, %{title: "changed_mission"})
    mission = Assessments.get_mission(mission.id)
    assert mission.title == "changed_mission"
  end

  test "all missions with category" do
    mission = insert(:mission, category: :mission)
    sidequest = insert(:mission, category: :sidequest)
    contest = insert(:mission, category: :contest)
    path = insert(:mission, category: :path)
    assert mission in Assessments.all_missions(:mission)
    assert sidequest in Assessments.all_missions(:sidequest)
    assert contest in Assessments.all_missions(:contest)
    assert path in Assessments.all_missions(:path)
  end

  test "due missions" do
    mission_before_now = insert(:mission, close_at: Timex.now(), is_published: true)
    mission_in_timerange = insert(:mission, 
      close_at: Timex.shift(Timex.now(), days: 4), is_published: true)
    mission_far = insert(:mission, close_at: Timex.shift(
      Timex.now(), weeks: 2), is_published: true)
    result = Assessments.missions_due_soon()
    assert mission_in_timerange in result
    refute mission_far in result
  end

  test "update question" do
    mission = insert(:mission)
    question = insert(:question)
    Assessments.update_question(question.id, %{weight: 10})
    question = Assessments.get_question(question.id)
    assert question.weight == 10
  end

  test "delete question" do
    mission = insert(:mission)
    question = insert(:question)
    Assessments.delete_question(question.id)
    assert Assessments.get_question(question.id) == nil
  end

  #test "mission and its questions" do
  #  mission1 = insert(:mission)
  #  mission2 = insert(:mission)
  #  question1 = insert(:question) 
  #  question2 = insert(:question)
  #  assert mission1 in Assessments.get_mission_and_questions(mission1.id)
  #end
end
