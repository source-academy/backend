defmodule Cadet.AssessmentsTest do
  use Cadet.DataCase

  alias Cadet.Assessments
  alias Cadet.Accounts

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
    {:ok, mission} =
      Assessments.create_mission(%{
        title: "mission",
        category: :mission,
        open_at: Timex.now(),
        close_at: Timex.shift(Timex.now(), days: 7)
      })

    {:ok, question} =
      Assessments.create_question(
        %{
          title: "question",
          weight: 5,
          question: %{}
        },
        :programming,
        mission.id
      )

    assert question.title == "question"
    assert question.type == :programming
    assert question.weight == 5
  end

  test "create multiple choice question" do
    {:ok, mission} =
      Assessments.create_mission(%{
        title: "mission",
        category: :mission,
        open_at: Timex.now(),
        close_at: Timex.shift(Timex.now(), days: 7)
      })

    {:ok, question} =
      Assessments.create_question(
        %{
          title: "question",
          weight: 5,
          question: %{}
        },
        :multiple_choice,
        mission.id
      )

    assert question.title == "question"
    assert question.type == :multiple_choice
    assert question.weight == 5
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

  test "create submission" do
    {:ok, mission} =
      Assessments.create_mission(%{
        title: "mission",
        category: :mission,
        open_at: Timex.now(),
        close_at: Timex.shift(Timex.now(), days: 7)
      })

    {:ok, student} =
      Accounts.create_user(%{first_name: "first", last_name: "last", role: :student})

    {:ok, submission} = Assessments.create_submission(mission, student)
    assert submission.status == :attempting
    assert submission.student == student
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

  test "all sidequests" do
    category =
      List.first(
        Enum.uniq(Enum.map(Assessments.all_missions(:sidequest), fn m -> m.category end))
      )

    assert category == nil or category == :sidequest
  end

  test "all open missions" do
    assert Enum.empty?(
             Enum.filter(
               Assessments.all_open_missions(:mission),
               &(!&1.is_published || Timex.after?(&1.open_at, Timex.now()))
             )
           )
  end

  test "due missions" do
    assert Enum.empty?(
             Enum.filter(
               Assessments.missions_due_soon(),
               &(!&1.is_published || Timex.after?(&1.open_at, Timex.now()) ||
                   Timex.after?(&1.close_at, Timex.add(Timex.now(), Duration.from_weeks(1))))
             )
           )
  end

  test "update question" do
    {:ok, mission} =
      Assessments.create_mission(%{
        title: "mission",
        category: :mission,
        open_at: Timex.now(),
        close_at: Timex.shift(Timex.now(), days: 7)
      })

    {:ok, question} =
      Assessments.create_question(
        %{
          title: "question",
          weight: 5,
          question: %{}
        },
        :multiple_choice,
        mission.id
      )

    Assessments.update_question(question.id, %{weight: 10})
    question = Assessments.get_question(question.id)
    assert question.weight == 10
  end

  test "pending gradings" do
    status =
      List.first(Enum.uniq(Enum.map(Assessments.all_pending_gradings(), fn g -> g.status end)))

    assert status == nil or status == :submitted
  end

  test "cannot open mission which hasn't been published" do
    {:ok, mission} =
      Assessments.create_mission(%{
        title: "mission",
        category: :mission,
        open_at: Timex.now(),
        close_at: Timex.shift(Timex.now(), days: 7)
      })

    {:ok, student} =
      Accounts.create_user(%{first_name: "first", last_name: "last", role: :student})

    assert Assessments.can_open?(mission.id, student, student) == false
  end

  test "delete question" do
    {:ok, mission} =
      Assessments.create_mission(%{
        title: "mission",
        category: :mission,
        open_at: Timex.now(),
        close_at: Timex.shift(Timex.now(), days: 7)
      })

    {:ok, question} =
      Assessments.create_question(
        %{
          title: "question",
          weight: 5,
          question: %{}
        },
        :multiple_choice,
        mission.id
      )

    Assessments.delete_question(question.id)
    assert Assessments.get_question(question.id) == nil
  end
end
