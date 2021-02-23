defmodule CadetWeb.AdminSettingsControllerTest do
  use CadetWeb.ConnCase

  alias CadetWeb.AdminSettingsController

  test "swagger" do
    AdminSettingsController.swagger_definitions()
    AdminSettingsController.swagger_path_update(nil)
  end

  describe "PUT /settings/sublanguage" do
    @tag authenticate: :admin
    test "succeeds", %{conn: conn} do
      insert(:sublanguage, %{chapter: 4, variant: "gpu"})

      conn =
        put(conn, build_url(), %{
          "chapter" => Enum.random(1..4),
          "variant" => "default"
        })

      assert response(conn, 200) == "OK"
    end

    @tag authenticate: :staff
    test "succeeds when no default sublanguage entry exists", %{conn: conn} do
      conn =
        put(conn, build_url(), %{
          "chapter" => Enum.random(1..4),
          "variant" => "default"
        })

      assert response(conn, 200) == "OK"
    end

    @tag authenticate: :student
    test "rejects forbidden request for non-staff users", %{conn: conn} do
      conn = put(conn, build_url(), %{"chapter" => 3, "variant" => "concurrent"})

      assert response(conn, 403) == "Forbidden"
    end

    @tag authenticate: :staff
    test "rejects requests with invalid params", %{conn: conn} do
      conn = put(conn, build_url(), %{"chapter" => 4, "variant" => "wasm"})

      assert response(conn, 400) == "Invalid parameter(s)"
    end

    @tag authenticate: :staff
    test "rejects requests with missing params", %{conn: conn} do
      conn = put(conn, build_url(), %{"variant" => "default"})

      assert response(conn, 400) == "Missing parameter(s)"
    end
  end

  defp build_url, do: "/v2/admin/settings/sublanguage"
end
