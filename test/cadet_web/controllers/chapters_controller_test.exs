defmodule CadetWeb.ChaptersControllerTest do
  use CadetWeb.ConnCase

  describe "GET /chapter" do
    @tag authenticate: :staff
    test "successful", %{conn: conn} do
      insert(:chapter)

      resp =
        conn
        |> get(build_url())
        |> json_response(200)

      %{"chapter" => %{"chapterno" => chapterno, "variant" => variant}} = resp
      assert chapterno == 1
      assert variant == "default"
    end
  end

  describe "POST /chapter/update/:id" do
    @tag authenticate: :staff
    test "successful", %{conn: conn} do
      insert(:chapter)

      no = Enum.random(1..4)

      resp =
        conn
        |> post(build_url(1), %{
          "chapterno" => no,
          "variant" => "default"
        })
        |> json_response(200)

      %{"chapter" => %{"chapterno" => chapterno, "variant" => variant}} = resp
      assert chapterno == no
      assert variant == "default"
    end
  end

  defp build_url, do: "/v1/chapter/"
  defp build_url(chapter_id), do: "#{build_url()}update/#{chapter_id}/"
end
