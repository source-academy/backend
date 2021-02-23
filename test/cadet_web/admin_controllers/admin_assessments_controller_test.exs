defmodule CadetWeb.AdminAssessmentsControllerTest do
  use CadetWeb.ConnCase
  use Timex

  import Ecto.Query
  import ExUnit.CaptureLog

  alias Cadet.Repo
  alias Cadet.Assessments.Assessment
  alias Cadet.Test.XMLGenerator
  alias CadetWeb.AdminAssessmentsController

  @local_name "test/fixtures/local_repo"

  setup do
    File.rm_rf!(@local_name)

    on_exit(fn ->
      File.rm_rf!(@local_name)
    end)

    Cadet.Test.Seeds.assessments()
  end

  test "swagger" do
    AdminAssessmentsController.swagger_path_create(nil)
    AdminAssessmentsController.swagger_path_delete(nil)
    AdminAssessmentsController.swagger_path_update(nil)
  end

  describe "POST /, unauthenticated" do
    test "unauthorized", %{conn: conn} do
      assessment = build(:assessment, type: "mission", is_published: true)
      questions = build_list(5, :question, assessment: nil)
      xml = XMLGenerator.generate_xml_for(assessment, questions)
      file = File.write("test/fixtures/local_repo/test.xml", xml)
      force_update = "false"
      body = %{assessment: file, forceUpdate: force_update}
      conn = post(conn, build_url(), body)
      assert response(conn, 401) =~ "Unauthorised"
    end
  end

  describe "POST /, student only" do
    @tag authenticate: :student
    test "unauthorized", %{conn: conn} do
      assessment = build(:assessment, type: "mission", is_published: true)
      questions = build_list(5, :question, assessment: nil)
      xml = XMLGenerator.generate_xml_for(assessment, questions)
      force_update = "false"
      body = %{assessment: xml, forceUpdate: force_update}
      conn = post(conn, build_url(), body)
      assert response(conn, 403) == "Forbidden"
    end
  end

  describe "POST /, staff only" do
    @tag authenticate: :staff
    test "successful", %{conn: conn} do
      assessment = build(:assessment, type: "mission", is_published: true)
      questions = build_list(5, :question, assessment: nil)

      xml = XMLGenerator.generate_xml_for(assessment, questions)
      force_update = "false"
      path = Path.join(@local_name, "connTest")
      file_name = "test.xml"
      location = Path.join(path, file_name)
      File.mkdir_p!(path)
      File.write!(location, xml)

      formdata = %Plug.Upload{
        content_type: "text/xml",
        filename: file_name,
        path: location
      }

      body = %{assessment: %{file: formdata}, forceUpdate: force_update}
      conn = post(conn, build_url(), body)
      number = assessment.number

      expected_assessment =
        Assessment
        |> where(number: ^number)
        |> Repo.one()

      assert response(conn, 200) == "OK"
      assert expected_assessment != nil
    end

    @tag authenticate: :staff
    test "upload empty xml", %{conn: conn} do
      xml = ""
      force_update = "true"
      path = Path.join(@local_name, "connTest")
      file_name = "test.xml"
      location = Path.join(path, file_name)
      File.mkdir_p!(path)
      File.write!(location, xml)

      formdata = %Plug.Upload{
        content_type: "text/xml",
        filename: file_name,
        path: location
      }

      body = %{assessment: %{file: formdata}, forceUpdate: force_update}

      err_msg =
        "Invalid XML fatal expected_element_start_tag file file_name_unknown line 1 col 1 "

      assert capture_log(fn ->
               conn = post(conn, build_url(), body)
               assert(response(conn, 400) == err_msg)
             end) =~ ~r/.*fatal: :expected_element_start_tag.*/
    end
  end

  describe "DELETE /:assessment_id, unauthenticated" do
    test "unauthorized", %{conn: conn} do
      assessment = insert(:assessment)
      conn = delete(conn, build_url(assessment.id))
      assert response(conn, 401) =~ "Unauthorised"
    end
  end

  describe "DELETE /:assessment_id, student only" do
    @tag authenticate: :student
    test "unauthorized", %{conn: conn} do
      assessment = insert(:assessment)
      conn = delete(conn, build_url(assessment.id))
      assert response(conn, 403) == "Forbidden"
    end
  end

  describe "DELETE /:assessment_id, staff only" do
    @tag authenticate: :staff
    test "successful", %{conn: conn} do
      assessment = insert(:assessment)
      conn = delete(conn, build_url(assessment.id))
      assert response(conn, 200) == "OK"
      assert Repo.get(Assessment, assessment.id) == nil
    end
  end

  describe "POST /:assessment_id, unauthenticated, publish" do
    test "unauthorized", %{conn: conn} do
      assessment = insert(:assessment)
      conn = post(conn, build_url(assessment.id), %{ isPublished: true })
      assert response(conn, 401) =~ "Unauthorised"
    end
  end

  describe "POST /:assessment_id, student only, publish" do
    @tag authenticate: :student
    test "forbidden", %{conn: conn} do
      assessment = insert(:assessment)
      conn = post(conn, build_url(assessment.id), %{ isPublished: true })
      assert response(conn, 403) == "Forbidden"
    end
  end

  describe "POST /:assessment_id, staff only, publish" do
    @tag authenticate: :staff
    test "successful toggle from published to unpublished", %{conn: conn} do
      assessment = insert(:assessment, is_published: true)
      conn = post(conn, build_url(assessment.id), %{ isPublished: false })
      expected = Repo.get(Assessment, assessment.id).is_published
      assert response(conn, 200) == "OK"
      assert expected == false
    end

    @tag authenticate: :staff
    test "successful toggle from unpublished to published", %{conn: conn} do
      assessment = insert(:assessment, is_published: false)
      conn = post(conn, build_url(assessment.id), %{ isPublished: true })
      expected = Repo.get(Assessment, assessment.id).is_published
      assert response(conn, 200) == "OK"
      assert expected == true
    end
  end

  describe "POST /:assessment_id, unauthenticated" do
    test "unauthorized", %{conn: conn} do
      assessment = insert(:assessment)
      conn = post(conn, build_url(assessment.id))
      assert response(conn, 401) =~ "Unauthorised"
    end
  end

  describe "POST /:assessment_id, student only" do
    @tag authenticate: :student
    test "forbidden", %{conn: conn} do
      new_open_at =
        Timex.now()
        |> Timex.beginning_of_day()
        |> Timex.shift(days: 3)
        |> Timex.shift(hours: 4)

      new_open_at_string =
        new_open_at
        |> Timex.format!("{ISO:Extended}")

      new_close_at = Timex.shift(new_open_at, days: 7)

      new_close_at_string =
        new_close_at
        |> Timex.format!("{ISO:Extended}")

      new_dates = %{openAt: new_open_at_string, closeAt: new_close_at_string}
      assessment = insert(:assessment)
      conn = post(conn, build_url(assessment.id), new_dates)
      assert response(conn, 403) == "Forbidden"
    end
  end

  describe "POST /:assessment_id, staff only" do
    @tag authenticate: :staff
    test "successful", %{conn: conn} do
      open_at =
        Timex.now()
        |> Timex.beginning_of_day()
        |> Timex.shift(days: 3)
        |> Timex.shift(hours: 4)

      close_at = Timex.shift(open_at, days: 7)
      assessment = insert(:assessment, %{open_at: open_at, close_at: close_at})

      new_open_at =
        open_at
        |> Timex.shift(days: 3)

      new_open_at_string =
        new_open_at
        |> Timex.format!("{ISO:Extended}")

      new_close_at =
        close_at
        |> Timex.shift(days: 5)

      new_close_at_string =
        new_close_at
        |> Timex.format!("{ISO:Extended}")

      new_dates = %{openAt: new_open_at_string, closeAt: new_close_at_string}

      conn =
        conn
        |> post(build_url(assessment.id), new_dates)

      assessment = Repo.get(Assessment, assessment.id)
      assert response(conn, 200) == "OK"
      assert [assessment.open_at, assessment.close_at] == [new_open_at, new_close_at]
    end

    @tag authenticate: :staff
    test "allowed to change open time of opened assessments", %{conn: conn} do
      open_at =
        Timex.now()
        |> Timex.beginning_of_day()
        |> Timex.shift(days: -3)
        |> Timex.shift(hours: 4)

      close_at = Timex.shift(open_at, days: 7)
      assessment = insert(:assessment, %{open_at: open_at, close_at: close_at})

      new_open_at =
        open_at
        |> Timex.shift(days: 6)

      new_open_at_string =
        new_open_at
        |> Timex.format!("{ISO:Extended}")

      close_at_string =
        close_at
        |> Timex.format!("{ISO:Extended}")

      new_dates = %{openAt: new_open_at_string, closeAt: close_at_string}

      conn =
        conn
        |> post(build_url(assessment.id), new_dates)

      assessment = Repo.get(Assessment, assessment.id)
      assert response(conn, 200) == "OK"
      assert [assessment.open_at, assessment.close_at] == [new_open_at, close_at]
    end

    @tag authenticate: :staff
    test "not allowed to set close time to before open time", %{conn: conn} do
      open_at =
        Timex.now()
        |> Timex.beginning_of_day()
        |> Timex.shift(days: 3)
        |> Timex.shift(hours: 4)

      close_at = Timex.shift(open_at, days: 7)
      assessment = insert(:assessment, %{open_at: open_at, close_at: close_at})

      new_close_at =
        open_at
        |> Timex.shift(days: -1)

      new_close_at_string =
        new_close_at
        |> Timex.format!("{ISO:Extended}")

      open_at_string =
        open_at
        |> Timex.format!("{ISO:Extended}")

      new_dates = %{openAt: open_at_string, closeAt: new_close_at_string}

      conn =
        conn
        |> post(build_url(assessment.id), new_dates)

      assessment = Repo.get(Assessment, assessment.id)
      assert response(conn, 400) == "New end date should occur after new opening date"
      assert [assessment.open_at, assessment.close_at] == [open_at, close_at]
    end

    @tag authenticate: :staff
    test "successful, set close time to before current time", %{conn: conn} do
      open_at =
        Timex.now()
        |> Timex.beginning_of_day()
        |> Timex.shift(days: -3)
        |> Timex.shift(hours: 4)

      close_at = Timex.shift(open_at, days: 7)
      assessment = insert(:assessment, %{open_at: open_at, close_at: close_at})

      new_close_at =
        Timex.now()
        |> Timex.shift(days: -1)

      new_close_at_string =
        new_close_at
        |> Timex.format!("{ISO:Extended}")

      open_at_string =
        open_at
        |> Timex.format!("{ISO:Extended}")

      new_dates = %{openAt: open_at_string, closeAt: new_close_at_string}

      conn =
        conn
        |> post(build_url(assessment.id), new_dates)

      assessment = Repo.get(Assessment, assessment.id)
      assert response(conn, 200) == "OK"
      assert [assessment.open_at, assessment.close_at] == [open_at, new_close_at]
    end

    @tag authenticate: :staff
    test "successful, set open time to before current time", %{conn: conn} do
      open_at =
        Timex.now()
        |> Timex.beginning_of_day()
        |> Timex.shift(days: 3)
        |> Timex.shift(hours: 4)

      close_at = Timex.shift(open_at, days: 7)
      assessment = insert(:assessment, %{open_at: open_at, close_at: close_at})

      new_open_at =
        Timex.now()
        |> Timex.shift(days: -1)

      new_open_at_string =
        new_open_at
        |> Timex.format!("{ISO:Extended}")

      close_at_string =
        close_at
        |> Timex.format!("{ISO:Extended}")

      new_dates = %{openAt: new_open_at_string, closeAt: close_at_string}

      conn =
        conn
        |> post(build_url(assessment.id), new_dates)

      assessment = Repo.get(Assessment, assessment.id)
      assert response(conn, 200) == "OK"
      assert [assessment.open_at, assessment.close_at] == [new_open_at, close_at]
    end
  end

  defp build_url, do: "/v2/admin/assessments/"
  defp build_url(assessment_id), do: "/v2/admin/assessments/#{assessment_id}"
end
