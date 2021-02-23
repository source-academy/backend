defmodule CadetWeb.SettingsControllerTest do
  use CadetWeb.ConnCase

  alias CadetWeb.SettingsController

  test "swagger" do
    SettingsController.swagger_definitions()
    SettingsController.swagger_path_index(nil)
  end

  describe "GET /settings/sublanguage" do
    test "succeeds", %{conn: conn} do
      insert(:sublanguage, %{chapter: 2, variant: "lazy"})

      resp = conn |> get(build_url()) |> json_response(200)

      assert %{"sublanguage" => %{"chapter" => 2, "variant" => "lazy"}} = resp
    end

    test "succeeds when no default sublanguage entry exists", %{conn: conn} do
      resp = conn |> get(build_url()) |> json_response(200)

      assert %{"sublanguage" => %{"chapter" => 1, "variant" => "default"}} = resp
    end
  end

  defp build_url, do: "/v1/settings/sublanguage"
end
