defmodule CadetWeb.AssessmentsControllerTest do
  use CadetWeb.ConnCase
  use Timex

  alias CadetWeb.AssessmentsController
  alias Cadet.Assessments.Assessment
  alias Cadet.Accounts.Role
  alias Cadet.Repo

  setup do
    Cadet.Test.Seeds.assessments()
  end

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
    describe "GET /, #{role}" do
      @tag authenticate: role
      test "renders assessments overview", %{conn: conn, assessments: assessments} do
        conn = get(conn, build_url())

        expected =
          assessments
          |> Map.values()
          |> Enum.map(fn a -> a.assessment end)
          |> Enum.sort(&open_at_asc_comparator/2)
          |> Enum.map(
            &%{
              "id" => &1.id,
              "title" => &1.title,
              "shortSummary" => &1.summary_short,
              "openAt" => format_datetime(&1.open_at),
              "closeAt" => format_datetime(&1.close_at),
              "type" => "#{&1.type}",
              "coverImage" => Cadet.Assessments.Image.url({&1.cover_picture, &1}),
              "maximumEXP" => 720
            }
          )

        assert ^expected = json_response(conn, 200)
      end

      @tag authenticate: role
      test "does not render unpublished assessments", %{conn: conn, assessments: assessments} do
        mission = assessments.mission

        {:ok, _} =
          mission.assessment
          |> Assessment.changeset(%{is_published: false})
          |> Repo.update()

        conn = get(conn, build_url())

        expected =
          assessments
          |> Map.delete(:mission)
          |> Map.values()
          |> Enum.map(fn a -> a.assessment end)
          |> Enum.sort(&open_at_asc_comparator/2)
          |> Enum.map(
            &%{
              "id" => &1.id,
              "title" => &1.title,
              "shortSummary" => &1.summary_short,
              "openAt" => format_datetime(&1.open_at),
              "closeAt" => format_datetime(&1.close_at),
              "type" => "#{&1.type}",
              "coverImage" => Cadet.Assessments.Image.url({&1.cover_picture, &1}),
              "maximumEXP" => 720
            }
          )

        assert ^expected = json_response(conn, 200)
      end
    end
  end

  defp build_url, do: "/v1/assessments/"
  defp build_url(assessment_id), do: "/v1/assessments/#{assessment_id}"

  defp open_at_asc_comparator(x, y), do: Timex.before?(x.open_at, y.open_at)
end
