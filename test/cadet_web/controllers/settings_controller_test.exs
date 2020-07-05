defmodule CadetWeb.SettingsControllerTest do
  use CadetWeb.ConnCase

  describe "GET /settings/sublanguage" do
    test "success", %{conn: conn} do
      insert(:sublanguage, %{chapter: 2, variant: "lazy"})

      resp =
        conn
        |> get(build_url())
        |> json_response(200)

      %{"sublanguage" => %{"chapter" => chapter, "variant" => variant}} = resp
      assert chapter == 2
      assert variant == "lazy"
    end

    test "success when no default sublanguage entry exists", %{conn: conn} do
      resp =
        conn
        |> get(build_url())
        |> json_response(200)

      %{"sublanguage" => %{"chapter" => chapter, "variant" => variant}} = resp
      assert chapter == 1
      assert variant == "default"
    end
  end

  describe "PUT /settings/sublanguage" do
    @tag authenticate: :admin
    test "success", %{conn: conn} do
      insert(:sublanguage, %{chapter: 1, variant: "wasm"})

      new_chapter = Enum.random(1..4)

      conn =
        put(conn, build_url(), %{
          "chapter" => new_chapter,
          "variant" => "default"
        })

      assert response(conn, 200) == "OK"
    end

    @tag authenticate: :staff
    test "success when no default sublanguage entry exists", %{conn: conn} do
      new_chapter = Enum.random(1..4)

      conn =
        put(conn, build_url(), %{
          "chapter" => new_chapter,
          "variant" => "default"
        })

      assert response(conn, 200) == "OK"
    end

    @tag authenticate: :student
    test "rejects forbidden request for non-staff users", %{conn: conn} do
      new_chapter = Enum.random(1..4)

      conn =
        put(conn, build_url(), %{
          "chapter" => new_chapter,
          "variant" => "default"
        })

      assert response(conn, 403) == "User not allowed to set default Playground sublanguage."
    end
  end

  defp build_url, do: "/v1/settings/sublanguage"
end
