defmodule CadetWeb.AdminCoursesControllerTest do
  use CadetWeb.ConnCase

  alias CadetWeb.AdminCoursesController

  test "swagger" do
    AdminCoursesController.swagger_definitions()
    AdminCoursesController.swagger_path_update_sublanguage(nil)
  end

  describe "PUT /courses/{courseId}/sublanguage" do
    @tag authenticate: :admin
    test "succeeds", %{conn: conn} do
      course = insert(:course, %{source_chapter: 4, source_variant: "gpu"})

      conn =
        put(conn, build_url(course.id), %{
          "chapter" => Enum.random(1..4),
          "variant" => "default"
        })

      assert response(conn, 200) == "OK"
    end

    @tag authenticate: :student
    test "rejects forbidden request for non-staff users", %{conn: conn} do
      course = insert(:course)
      conn = put(conn, build_url(course.id), %{"chapter" => 3, "variant" => "concurrent"})

      assert response(conn, 403) == "Forbidden"
    end

    @tag authenticate: :staff
    test "rejects requests with invalid course id", %{conn: conn} do
      course = insert(:course)
      conn = put(conn, build_url(course.id + 1), %{"chapter" => 3, "variant" => "concurrent"})
    end

    @tag authenticate: :staff
    test "rejects requests with invalid params", %{conn: conn} do
      course = insert(:course)
      conn = put(conn, build_url(course.id), %{"chapter" => 4, "variant" => "wasm"})

      assert response(conn, 400) == "Invalid parameter(s)"
    end

    @tag authenticate: :staff
    test "rejects requests with missing params", %{conn: conn} do
      course = insert(:course)
      conn = put(conn, build_url(course.id), %{"variant" => "default"})

      assert response(conn, 400) == "Missing parameter(s)"
    end
  end

  defp build_url(course_id), do: "/v2/admin/courses/#{course_id}/sublanguage"
end
