defmodule CadetWeb.UserControllerTest do
  use CadetWeb.ConnCase

  import Cadet.Factory

  alias CadetWeb.UserController

  test "swagger" do
    assert is_map(UserController.swagger_definitions())
    assert is_map(UserController.swagger_path_index(nil))
  end

  describe "GET /user" do
    @tag authenticate: :student
    test "success, student", %{conn: conn} do
      user = conn.assigns.current_user
      assessment = insert(:assessment, %{is_published: true})
      question = insert(:question, %{assessment: assessment})
      submission = insert(:submission, %{assessment: assessment, student: user})
      insert(:answer, %{question: question, submission: submission, grade: 50, adjustment: -10})

      conn = get(conn, "/v1/user", nil)
      body = json_response(conn, 200)
      assert response(conn, 200)
      assert %{"name" => user.name, "role" => "#{user.role}", "grade" => 40} == body
    end

    @tag authenticate: :staff
    test "success, staff", %{conn: conn} do
      user = conn.assigns.current_user
      conn = get(conn, "/v1/user", nil)
      body = json_response(conn, 200)
      assert response(conn, 200)
      assert %{"name" => user.name, "role" => "#{user.role}", "grade" => 0} == body
    end

    test "unauthorized", %{conn: conn} do
      conn = get(conn, "/v1/user", nil)
      assert response(conn, 401) =~ "Unauthorised"
    end
  end
end
