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

  # Controllers fully migrated to open_api_spex `operation` specs. Every routed
  # action on a listed controller must have an operation (or be in @doc_exempt /
  # @dead_routes). Add a controller here as it is migrated; once every
  # controller is listed, replace the scoped assertion below with a blanket one.
  @migrated_controllers [
    CadetWeb.IncentivesController,
    CadetWeb.AdminAchievementsController
  ]

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
    test "every migrated controller documents all of its actions" do
      undocumented =
        documentable_routes()
        |> Enum.filter(fn {plug, _action} -> plug in @migrated_controllers end)
        |> Enum.reject(fn route ->
          route in @doc_exempt or route in @dead_routes or documented?(route)
        end)

      assert undocumented == [],
             "Migrated controllers with undocumented actions: #{inspect(undocumented)}"
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
end
