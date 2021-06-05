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
      # This line causes a false positive with MultiAliasImportRequireUse
      # credo:disable-for-next-line
      import Plug.Conn
      import Phoenix.ConnTest
      import CadetWeb.Router.Helpers
      import Cadet.{AssertHelper, Factory}

      # The default endpoint for testing
      @endpoint CadetWeb.Endpoint

      # Helper function for formatting datetime for views
      import CadetWeb.ViewHelper

      # Helper function
      def sign_in(conn, user) do
        CadetWeb.ConnCase.sign_in(conn, user)
      end
    end
  end

  setup tags do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(Cadet.Repo)

    unless tags[:async] do
      Ecto.Adapters.SQL.Sandbox.mode(Cadet.Repo, {:shared, self()})
    end

    conn = Phoenix.ConnTest.build_conn()

    if tags[:authenticate] do
      course_registration =
        cond do
          is_atom(tags[:authenticate]) ->
            Cadet.Factory.insert(:course_registration, %{role: tags[:authenticate]})

          # :TODO: This is_map case has not been handled. To recheck in the future.
          is_map(tags[:authenticate]) ->
            tags[:authenticate]

          true ->
            nil
        end

      # We assign course_id to the conn during testing, so that we can generate the correct
      # course URL for the user created during the test. The course_id is assigned here instead
      # of the course_registration since we want the router plug to assign the course_registration
      # when actually accessing the endpoint during the test.
      conn =
        sign_in(conn, course_registration.user)
        |> assign(:course_id, course_registration.course_id)

      {:ok, conn: conn}
    else
      {:ok, conn: conn}
    end
  end

  def sign_in(conn, user) do
    conn
    |> Cadet.Auth.Guardian.Plug.sign_in(user)
    |> assign(:current_user, user)
  end
end
