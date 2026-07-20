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

  alias Cadet.Factory
  alias Phoenix.ConnTest

  using do
    quote do
      # Import conveniences for testing with connections
      # This line causes a false positive with MultiAliasImportRequireUse
      # credo:disable-for-next-line
      import Plug.Conn
      # post/put/patch are overridden below to send map bodies as JSON.
      import Phoenix.ConnTest, except: [post: 2, post: 3, put: 2, put: 3, patch: 2, patch: 3]
      import CadetWeb.Router.Helpers
      import Cadet.{AssertHelper, Factory}
      alias CadetWeb.ConnCase

      # The default endpoint for testing
      @endpoint CadetWeb.Endpoint

      # Helper function for formatting datetime for views
      import CadetWeb.ViewHelper

      # Send map/list request bodies as `application/json` (matching what the
      # frontend sends in production), so `OpenApiSpex.Plug.CastAndValidate`
      # accepts them. Multipart uploads (bodies containing `%Plug.Upload{}`) and
      # raw string bodies are dispatched unchanged.
      def post(conn, path, params \\ nil),
        do: ConnCase.json_dispatch(conn, @endpoint, :post, path, params)

      def put(conn, path, params \\ nil),
        do: ConnCase.json_dispatch(conn, @endpoint, :put, path, params)

      def patch(conn, path, params \\ nil),
        do: ConnCase.json_dispatch(conn, @endpoint, :patch, path, params)

      # Helper function
      def sign_in(conn, user) do
        ConnCase.sign_in(conn, user)
      end
    end
  end

  setup tags do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(Cadet.Repo)

    unless tags[:async] do
      Ecto.Adapters.SQL.Sandbox.mode(Cadet.Repo, {:shared, self()})
    end

    conn = ConnTest.build_conn()

    if tags[:authenticate] do
      course = Factory.insert(:course, id: tags[:course_id])
      user = Factory.insert(:user, %{latest_viewed_course: course})
      group = if tags[:group], do: Factory.insert(:group, course: course), else: nil

      course_registration =
        cond do
          is_atom(tags[:authenticate]) ->
            Factory.insert(:course_registration, %{
              user: user,
              course: course,
              role: tags[:authenticate],
              group: group
            })

          # :TODO: This is_map case has not been handled. To recheck in the future.
          is_map(tags[:authenticate]) ->
            Factory.insert(:course_registration, tags[:authenticate])

          true ->
            nil
        end

      # We assign course_id to the conn during testing, so that we can generate the correct
      # course URL for the user created during the test. The course_id is assigned here instead
      # of the course_registration since we want the router plug to assign the course_registration
      # when actually accessing the endpoint during the test.
      conn =
        conn
        |> sign_in(course_registration.user)
        |> assign(:course_id, course_registration.course_id)
        |> assign(:test_cr, course_registration)

      {:ok, conn: conn}
    else
      if tags[:sign_in] do
        user = Factory.insert(:user, tags[:sign_in])
        conn = sign_in(conn, user)
        {:ok, conn: conn}
      else
        {:ok, conn: conn}
      end
    end
  end

  def sign_in(conn, user) do
    conn
    |> Cadet.Auth.Guardian.Plug.sign_in(user)
    |> assign(:current_user, user)
  end

  @doc false
  def json_dispatch(conn, endpoint, method, path, params) do
    case encode_json_body(params) do
      {:ok, body} ->
        conn
        |> put_req_header("content-type", "application/json")
        |> ConnTest.dispatch(endpoint, method, path, body)

      :passthrough ->
        ConnTest.dispatch(conn, endpoint, method, path, params)
    end
  end

  # Encode map/list bodies as JSON. Anything not JSON-encodable -- multipart
  # uploads (`%Plug.Upload{}`), tuples, etc. -- and raw string bodies are passed
  # through unchanged (dispatched as-is, e.g. multipart/form-data).
  defp encode_json_body(params) when is_map(params) or is_list(params) do
    case Jason.encode(params) do
      {:ok, body} -> {:ok, body}
      {:error, _} -> :passthrough
    end
  end

  defp encode_json_body(_), do: :passthrough
end
