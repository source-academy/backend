defmodule CadetWeb.UserControllerTest do
  use CadetWeb.ConnCase

  import Cadet.Factory

  alias Cadet.Repo
  alias CadetWeb.UserController
  alias Cadet.Assessments.{Assessment, AssessmentType}

  test "swagger" do
    assert is_map(UserController.swagger_definitions())
    assert is_map(UserController.swagger_path_index(nil))
  end

  describe "GET /user" do
    @tag authenticate: :student
    test "success, student non-story fields", %{conn: conn} do
      user = conn.assigns.current_user
      assessment = insert(:assessment, %{is_published: true})
      question = insert(:question, %{assessment: assessment})
      submission = insert(:submission, %{assessment: assessment, student: user})
      insert(:answer, %{question: question, submission: submission, grade: 50, adjustment: -10})

      resp =
        conn
        |> get("/v1/user")
        |> json_response(200)
        |> Map.delete("story")

      expected = %{"name" => user.name, "role" => "#{user.role}", "grade" => 40}

      assert expected == resp
    end

    # This also tests for the case where assessment has no submission
    @tag authenticate: :student
    test "success, student story ordering", %{conn: conn} do
      early_assessments = build_assessments_starting_at(Timex.shift(Timex.now(), days: -3))
      late_assessments = build_assessments_starting_at(Timex.shift(Timex.now(), days: -1))

      for assessment <- early_assessments ++ late_assessments do
        story =
          conn
          |> get("/v1/user")
          |> json_response(200)
          |> Map.get("story")

        assert story == assessment.story

        {:ok, _} = Repo.delete(assessment)
      end
    end

    @tag authenticate: :student
    test "success, student story skips assessment without story", %{conn: conn} do
      assessments = build_assessments_starting_at(Timex.shift(Timex.now(), days: -1))

      assessments
      |> Enum.fetch!(0)
      |> Assessment.changeset(%{story: nil})
      |> Repo.update()

      story =
        conn
        |> get("/v1/user")
        |> json_response(200)
        |> Map.get("story")

      assert story == Enum.fetch!(assessments, 1).story
    end

    @tag authenticate: :student
    test "success, student story skips unopen assessments", %{conn: conn} do
      build_assessments_starting_at(Timex.shift(Timex.now(), days: 1))
      build_assessments_starting_at(Timex.shift(Timex.now(), months: -1))

      valid_assessments = build_assessments_starting_at(Timex.shift(Timex.now(), days: -1))

      for assessment <- valid_assessments do
        assessment
        |> Assessment.changeset(%{is_published: false})
        |> Repo.update!()
      end

      story =
        conn
        |> get("/v1/user")
        |> json_response(200)
        |> Map.get("story")

      assert story == nil
    end

    @tag authenticate: :student
    test "success, student story does not skip attempting or attempted", %{conn: conn} do
      user = conn.assigns.current_user

      [assessment | _] = build_assessments_starting_at(Timex.shift(Timex.now(), days: -3))

      # Submit for i-th assessment, expect (i+1)th story to be returned
      for status <- [:attempting, :attempted] do
        submission = insert(:submission, %{student: user, assessment: assessment, status: status})

        resp_story =
          conn
          |> get("/v1/user")
          |> json_response(200)
          |> Map.get("story")

        assert resp_story == assessment.story

        Repo.delete(submission)
      end
    end

    @tag authenticate: :student
    test "success, student story skips submitted", %{conn: conn} do
      user = conn.assigns.current_user

      early_assessments = build_assessments_starting_at(Timex.shift(Timex.now(), days: -3))
      late_assessments = build_assessments_starting_at(Timex.shift(Timex.now(), days: -1))
      assessments_with_indices = Enum.with_index(early_assessments ++ late_assessments)

      # Submit for i-th assessment, expect (i+1)th story to be returned
      for {assessment, idx} <- Enum.drop(assessments_with_indices, -1) do
        insert(:submission, %{student: user, assessment: assessment, status: :submitted})

        {expected_assessment, _} = Enum.fetch!(assessments_with_indices, idx + 1)

        resp_story =
          conn
          |> get("/v1/user")
          |> json_response(200)
          |> Map.get("story")

        assert resp_story == expected_assessment.story
      end
    end

    @tag authenticate: :staff
    test "success, staff", %{conn: conn} do
      user = conn.assigns.current_user
      assessments = build_assessments_starting_at(Timex.shift(Timex.now(), days: -3))

      resp =
        conn
        |> get("/v1/user")
        |> json_response(200)

      expected = %{"name" => user.name, "role" => "#{user.role}", "grade" => 0, "story" => nil}

      assert expected == resp
    end

    test "unauthorized", %{conn: conn} do
      conn = get(conn, "/v1/user", nil)
      assert response(conn, 401) =~ "Unauthorised"
    end
  end

  defp build_assessments_starting_at(time) do
    type_order_map =
      AssessmentType.__enum_map__()
      |> Enum.with_index()
      |> Enum.reduce(%{}, fn {type, idx}, acc -> Map.put(acc, type, idx) end)

    AssessmentType.__enum_map__()
    |> Enum.map(
      &build(:assessment, %{
        type: &1,
        is_published: true,
        open_at: time,
        close_at: Timex.shift(time, days: 10)
      })
    )
    |> Enum.shuffle()
    |> Enum.map(&insert(&1))
    |> Enum.sort(&(type_order_map[&1.type] < type_order_map[&2.type]))
  end
end
