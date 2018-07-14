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
      @tag authenticate: role
      test "renders assessments overview", %{conn: conn, assessments: assessments} do
        open_at_asc_comparator = fn x, y -> Timex.before?(x.open_at, y.open_at) end

        conn = get(conn, build_url())

        expected =
          assessments
          |> Map.values()
          |> Enum.map(fn a -> a.assessment end)
          |> Enum.sort(open_at_asc_comparator)
          |> Enum.map(
            &%{
              "id" => &1.id,
              "title" => &1.title,
              "shortSummary " => &1.summary_short,
              "openAt" => DateTime.to_string(&1.open_at),
              "closeAt" => DateTime.to_string(&1.close_at),
              "type" => "#{&1.type}",
              "coverImage" => Cadet.Assessments.Image.url({&1.cover_picture, &1}),
              "maximumEXP" => 600
            }
          )

        assert expected == json_response(conn, 200)
      end
    end
  end

  defp build_url, do: "/v1/assessments/"
  defp build_url(assessment_id), do: "/v1/assessments/#{assessment_id}"
end
