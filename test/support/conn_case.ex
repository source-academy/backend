defmodule CadetWeb.ConnCase do
  @moduledoc """
  This module defines the test case to be used by
  tests that require setting up a connection.

  Such tests rely on `Phoenix.ConnTest` and also
  import other functionality to make it easier
  to build common datastructures and query the data layer.

  Finally, if the test case interacts with the database,
  it cannot be async. For this reason, every test runs
  inside a transaction which is reset at the beginning
  of the test unless the test case is marked as async.
  """

  use ExUnit.CaseTemplate

  import Plug.Conn

  using do
    quote do
      # Import conveniences for testing with connections
      use Phoenix.ConnTest
      import CadetWeb.Router.Helpers

      # The default endpoint for testing
      @endpoint CadetWeb.Endpoint
    end
  end

  setup tags do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(Cadet.Repo)

    unless tags[:async] do
      Ecto.Adapters.SQL.Sandbox.mode(Cadet.Repo, {:shared, self()})
    end

    conn = Phoenix.ConnTest.build_conn()

    if tags[:authenticate] != nil do
      user = cond do
        is_atom(tags[:authenticate]) ->
          Cadet.Factory.insert(:user, %{role: tags[:authenticate]})
        is_map(tags[:authenticate]) ->
          tags[:authenticate]
      end

      conn =
        conn
        |> Cadet.Auth.Guardian.Plug.sign_in(user)
        |> assign(:current_user, user)

      {:ok, conn: conn}
    else
      {:ok, conn: conn}
    end
  end
end
