defmodule CadetWeb.RouterTest do
  use CadetWeb.ConnCase

  test "serves the Swagger UI at /swagger", %{conn: conn} do
    body = conn |> get("/swagger") |> response(200)
    # The UI is configured to load the spec from the RenderSpec route.
    assert body =~ "/swagger/openapi.json"
  end

  test "serves the OpenAPI 3.0 spec as JSON at /swagger/openapi.json", %{conn: conn} do
    resp = conn |> get("/swagger/openapi.json") |> json_response(200)
    assert %{"openapi" => "3.0" <> _, "paths" => paths} = resp
    assert map_size(paths) > 0
  end
end
