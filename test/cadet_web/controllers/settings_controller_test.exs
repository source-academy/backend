defmodule CadetWeb.SettingsControllerTest do
  use CadetWeb.ConnCase

  describe "GET /settings/sublanguage" do
    test "successfully returns default sublanguage", %{conn: conn} do
      insert(:sublanguage, %{chapter: 2, variant: "lazy"})

      resp =
        conn
        |> get(build_url())
        |> json_response(200)

      %{"sublanguage" => %{"chapter" => chapter, "variant" => variant}} = resp
      assert chapter == 2
      assert variant == "lazy"
    end

    test "successfully returns default when no entry exists", %{conn: conn} do
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
    @tag authenticate: :staff
    test "successfully updates existing sublanguage", %{conn: conn} do
      insert(:sublanguage, %{chapter: 1, variant: "wasm"})

      new_chapter = Enum.random(1..4)

      resp =
        conn
        |> put(build_url(), %{
          "chapter" => new_chapter,
          "variant" => "default"
        })
        |> json_response(200)

      %{"sublanguage" => %{"chapter" => chapter, "variant" => variant}} = resp
      assert chapter == new_chapter
      assert variant == "default"
    end

    @tag authenticate: :staff
    test "successful when no chapter inserted", %{conn: conn} do
      new_chapter = Enum.random(1..4)

      resp =
        conn
        |> put(build_url(), %{
          "chapter" => new_chapter,
          "variant" => "default"
        })
        |> json_response(200)

      %{"sublanguage" => %{"chapter" => chapter, "variant" => variant}} = resp
      assert chapter == new_chapter
      assert variant == "default"
    end
  end

  defp build_url, do: "/v1/settings/sublanguage"
end
