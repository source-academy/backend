defmodule CadetWeb.ApiSpecTest do
  @moduledoc """
  Guards for the generated OpenAPI document (`CadetWeb.ApiSpec`).

  These tests are the safety net for the phoenix_swagger -> open_api_spex
  migration. They ensure the spec always builds and serialises, that no route
  points at a non-existent action, and that every controller already migrated
  to open_api_spex stays fully documented.
  """
  use ExUnit.Case, async: true

  alias CadetWeb.{ApiSpec, Router}

  # Routes intentionally excluded from the OpenAPI document (infrastructure /
  # non-/v2 endpoints that do not belong in the API contract).
  @doc_exempt [
    {CadetWeb.DefaultController, :index},
    {CadetWeb.JWKSController, :index}
  ]

  # Routes whose controller action does NOT exist -- every call 500s. Left in
  # place per decision (flag, don't delete); see the FIXME comments on
  # `operation :bulk_upload, false` / `operation :save_chosen_comments, false`.
  # Tracked here so the dead-route guard passes while surfacing them.
  @dead_routes [
    {CadetWeb.AdminTeamsController, :bulk_upload},
    {CadetWeb.AICodeAnalysisController, :save_chosen_comments}
  ]

  @http_verbs ~w(get post put patch delete)

  describe "the generated OpenAPI document" do
    test "builds and serialises to JSON" do
      spec = ApiSpec.spec()
      assert %OpenApiSpex.OpenApi{openapi: "3.0.0"} = spec

      # Round-tripping to a plain map and encoding only succeeds for a
      # structurally sound document with all schema modules resolved.
      assert {:ok, _json} = spec |> OpenApiSpex.OpenApi.to_map() |> Jason.encode()
    end
  end

  describe "route <-> action integrity" do
    test "no route points at a non-existent action (beyond the known dead set)" do
      unexpected =
        documentable_routes()
        |> Enum.reject(fn {plug, action} -> function_exported?(plug, action, 2) end)
        |> Kernel.--(@dead_routes)

      assert unexpected == [],
             "Routes point at actions that do not exist: #{inspect(unexpected)}"
    end
  end

  describe "documentation completeness" do
    test "every documentable route has an operation" do
      undocumented =
        documentable_routes()
        |> Enum.reject(fn route ->
          route in @doc_exempt or route in @dead_routes or documented?(route)
        end)

      assert undocumented == [],
             "Routes without an OpenAPI operation: #{inspect(undocumented)}"
    end
  end

  describe "path parameters" do
    test "every path-template parameter is declared by its operations" do
      spec_map = OpenApiSpex.OpenApi.to_map(ApiSpec.spec())
      problems = Enum.flat_map(spec_map["paths"], &path_param_problems/1)

      assert problems == [],
             "Operations missing declared path params: #{inspect(problems)}"
    end
  end

  # All routes that are candidates for documentation: controller actions only
  # (drops `forward`s, whose plug_opts is not an action atom), de-duplicated.
  defp documentable_routes do
    Router.__routes__()
    |> Enum.filter(fn route -> is_atom(route.plug_opts) end)
    |> Enum.map(fn route -> {route.plug, route.plug_opts} end)
    |> Enum.uniq()
  end

  defp documented?({plug, action}) do
    function_exported?(plug, :open_api_operation, 1) and
      not is_nil(plug.open_api_operation(action))
  end

  # For one path, return {path, verb, missing_params} for each operation whose
  # declared path parameters do not cover every `{param}` in the path template.
  defp path_param_problems({path, item}) do
    template_params =
      ~r/\{(\w+)\}/
      |> Regex.scan(path)
      |> Enum.map(fn [_, param] -> param end)

    path_level = declared_path_params(Map.get(item, "parameters", []))

    item
    |> Enum.filter(fn {verb, _op} -> verb in @http_verbs end)
    |> Enum.flat_map(fn {verb, op} ->
      declared = path_level ++ declared_path_params(Map.get(op, "parameters", []))

      case template_params -- declared do
        [] -> []
        missing -> [{path, verb, missing}]
      end
    end)
  end

  defp declared_path_params(params) do
    params
    |> Enum.filter(fn param -> param["in"] == "path" end)
    |> Enum.map(fn param -> param["name"] end)
  end
end
