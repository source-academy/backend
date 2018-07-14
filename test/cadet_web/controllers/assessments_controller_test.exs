defmodule CadetWeb.AssessmentsControllerTest do
  use CadetWeb.ConnCase

  alias CadetWeb.AssessmentsController
  alias Cadet.Accounts.Role
  alias Cadet.Repo

  test "swagger" do
    AssessmentsController.swagger_definitions()
    AssessmentsController.swagger_path_index(nil)
    AssessmentsController.swagger_path_show(nil)
  end

  describe "GET /, unauthenticated" do
    test "unauthorized", %{conn: conn} do
      conn = get(conn, build_url())
      assert response(conn, 401) =~ "Unauthorised"
    end
  end

  describe "GET /:assessment_id, unauthenticated" do
    test "unauthorized", %{conn: conn} do
      conn = get(conn, build_url(1))
      assert response(conn, 401) =~ "Unauthorised"
    end
  end

  # All roles should see the same overview page
  for role <- Role.__enum_map__() do
    setup do
      Cadet.Test.Seeds.call()
    end

    describe "GET /, #{role}" do
      # assessments = Repo.all(Cadet.Assessments)
    end
  end

  defp build_url, do: "/v1/assessments/"
  defp build_url(assessment_id), do: "/v1/assessments/#{assessment_id}"
end
