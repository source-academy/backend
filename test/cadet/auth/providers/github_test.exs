defmodule Cadet.Auth.Providers.GitHubTest do
  use ExUnit.Case, async: false

  alias Cadet.Auth.Providers.GitHub
  alias Plug.Conn, as: PlugConn

  @username "username"
  @name "name"

  @dummy_access_token "dummy_access_token"

  setup_all do
    Application.ensure_all_started(:bypass)
    bypass = Bypass.open()

    {:ok, bypass: bypass}
  end

  defp config(bypass) do
    %{
      clients: %{"dummy_client_id" => "dummy_client_secret"},
      token_url: "http://localhost:#{bypass.port}/login/oauth/access_token",
      user_api: "http://localhost:#{bypass.port}/user"
    }
  end

  defp bypass_return_token(bypass) do
    Bypass.stub(bypass, "POST", "login/oauth/access_token", fn conn ->
      conn
      |> PlugConn.put_resp_header("content-type", "application/json")
      |> PlugConn.resp(200, ~s({"access_token":"#{@dummy_access_token}"}))
    end)
  end

  defp bypass_api_call(bypass) do
    Bypass.stub(bypass, "GET", "user", fn conn ->
      conn
      |> PlugConn.put_resp_header("content-type", "application/json")
      |> PlugConn.resp(200, ~s({"login":"#{@username}","name":"#{@name}"}))
    end)
  end

  test "successful", %{bypass: bypass} do
    bypass_return_token(bypass)
    bypass_api_call(bypass)

    assert {:ok, %{token: @dummy_access_token, username: @username}} ==
             GitHub.authorise(config(bypass), %{
               code: "",
               client_id: "dummy_client_id",
               redirect_uri: ""
             })
  end

  test "invalid github client id", %{bypass: bypass} do
    bypass_return_token(bypass)
    bypass_api_call(bypass)

    assert {:error, :invalid_credentials, "Invalid client id"} ==
             GitHub.authorise(config(bypass), %{
               code: "",
               client_id: "invalid_client_id",
               redirect_uri: ""
             })
  end

  test "non-successful HTTP status (access token)", %{bypass: bypass} do
    Bypass.stub(bypass, "POST", "login/oauth/access_token", fn conn ->
      PlugConn.resp(conn, 403, "")
    end)

    assert {:error, :upstream, "Status code 403 from GitHub"} ==
             GitHub.authorise(config(bypass), %{
               code: "",
               client_id: "dummy_client_id",
               redirect_uri: ""
             })
  end

  test "error token response", %{bypass: bypass} do
    Bypass.stub(bypass, "POST", "login/oauth/access_token", fn conn ->
      conn
      |> PlugConn.put_resp_header("content-type", "application/json")
      |> PlugConn.resp(200, ~s({"error":"bad_verification_code"}))

      assert {:error, :invalid_credentials, "Error from GitHub: bad_verification_code"} ==
               GitHub.authorise(config(bypass), %{
                 code: "",
                 client_id: "dummy_client_id",
                 redirect_uri: ""
               })
    end)
  end

  test "non-successful HTTP status (user api call)", %{bypass: bypass} do
    bypass_return_token(bypass)

    Bypass.stub(bypass, "GET", "user", fn conn ->
      PlugConn.resp(conn, 401, "")
    end)

    assert {:error, :upstream, "Status code 401 from GitHub"}

    GitHub.authorise(config(bypass), %{
      code: "",
      client_id: "dummy_client_id",
      redirect_uri: ""
    })
  end

  test "get_name successful", %{bypass: bypass} do
    bypass_api_call(bypass)

    assert {:ok, @name} == GitHub.get_name(config(bypass), @dummy_access_token)
  end

  test "get_name non-successful HTTP status", %{bypass: bypass} do
    Bypass.stub(bypass, "GET", "user", fn conn ->
      PlugConn.resp(conn, 401, "")
    end)

    assert {:error, :upstream, "Status code 401 from GitHub"} ==
             GitHub.get_name(config(bypass), "invalid_access_token")
  end
end
