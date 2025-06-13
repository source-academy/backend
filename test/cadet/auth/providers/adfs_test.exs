defmodule Cadet.Auth.Providers.ADFSTest do
  @moduledoc """
  This test module uses pre-recorded HTTP responses saved by ExVCR. This allows
  testing without actual external ADFS API calls.

  If you need to re-record these responses, set the ADFS API key in
  config/test.exs, retrieve a ADFS authorisation token, delete the pre-recorded
  responses, and then run

      TOKEN=auth_code_goes_here mix test

  You can retrieve the authorisation token by manually hitting the ADFS
  endpoints, or just by logging in to ADFS in your browser and extracting the
  token from the Authorization header in API requests.

  If you need to re-record the authorise responses, you will have to hit ADFS
  manually to get an authorisation code, and set the appropriate environment
  variables (see the module attributes defined below).

  Note that all the cassettes are marked as custom as they have been manually
  edited to suit the particular test case.
  """

  use ExUnit.Case, async: true
  use ExVCR.Mock, adapter: ExVCR.Adapter.Hackney

  alias Cadet.Auth.Providers.ADFS

  @code System.get_env("CODE") || "CODE"
  @redirect_uri System.get_env("REDIRECT_URI") || "http://localhost:8000/login"
  @client_id System.get_env("CLIENT_ID") || "CLIENT_ID"
  @token System.get_env("TOKEN") ||
           "eyJhbGciOiJSUzI1NiIsInR5cCI6IkpXVCJ9.eyJTYW1BY2NvdW50TmFtZSI6ImUwMTIzNDU2IiwiZGlzcGxheU5hbWUiOiJZb3VyIE5hbWUiLCJpYXQiOjE1MTYyMzkwMjIsImV4cCI6MjAwMDAwMDAwMH0.YkXG5snv_aMQtctrhrdHIrJbt0gmDABuUV-7YJ4FCHM2G_b6N_cEWssUsaiTEsjJzTCVvTdMdgH4q4jqfAZ75-h9WTDv6erDk7Uee8k0HJ4Gi08gX7u_efRcqLRi2ydv1ed74LCoox_SLi97C5tYZBTJwMI6Ljm1HIO4VVGwbZpDXTjxwqvMzUw0bxDYtPgVhU-PE79rcvmGNuaWzt5GloQl6hgVYWtJpCbKh_fTT_d5czsq0TWXsCwSY9OK96ho966PrryjBSAvfjSFD4rNUb2c8vDKO1ozjMEpDBWgvjdUJXi4rdTdqFny-bgFG2dFZksIgnAZxaryH3m0AcIUOg"
  @name "Your Name"

  @config %{
    token_endpoint: "https://my-adfs/adfs/oauth2/token"
  }

  setup_all do
    HTTPoison.start()
  end

  describe "authorise" do
    test "using a valid code" do
      use_cassette "adfs/authorise#1", custom: true do
        assert {:ok, _} =
                 ADFS.authorise(@config, %{
                   code: @code,
                   client_id: @client_id,
                   redirect_uri: @redirect_uri
                 })
      end
    end

    test "using an invalid code" do
      use_cassette "adfs/authorise#2", custom: true do
        assert {:error, :upstream,
                "Status code 400 from ADFS: {\"error\":\"invalid_grant\",\"error_description\":\"MSIS9612: The authorization code received in \\u0027code\\u0027 parameter is invalid. \"}"} =
                 ADFS.authorise(@config, %{
                   code: @code <> "_invalid",
                   client_id: @client_id,
                   redirect_uri: @redirect_uri
                 })
      end
    end

    test "using an invalid redirect_uri" do
      use_cassette "adfs/authorise#3", custom: true do
        assert {:error, :upstream,
                "Status code 400 from ADFS: {\"error\":\"invalid_request\",\"error_description\":\"MSIS9609: The \\u0027redirect_uri\\u0027 parameter is invalid. No redirect uri with the specified value is registered for the received \\u0027client_id\\u0027. \"}"} =
                 ADFS.authorise(@config, %{
                   code: @code,
                   client_id: @client_id,
                   redirect_uri: @redirect_uri <> "_invalid"
                 })
      end
    end

    test "using an invalid client_id" do
      use_cassette "adfs/authorise#4", custom: true do
        assert {:error, :upstream,
                "Status code 400 from ADFS: {\"error\":\"invalid_client\",\"error_description\":\"MSIS9607: The \\u0027client_id\\u0027 parameter in the request is invalid. No registered client is found with this identifier.\"}"} =
                 ADFS.authorise(@config, %{
                   code: @code,
                   client_id: @client_id <> "_invalid",
                   redirect_uri: @redirect_uri
                 })
      end
    end

    test "non-success HTTP code from upstream" do
      use_cassette "adfs/authorise#5", custom: true do
        assert {:error, :upstream,
                "Status code 500 from ADFS: {\"error\":\"invalid_client\",\"error_description\":\"boom.\"}"} =
                 ADFS.authorise(@config, %{
                   code: @code,
                   client_id: @client_id,
                   redirect_uri: @redirect_uri
                 })
      end
    end

    test "no username in token from upstream" do
      use_cassette "adfs/authorise#6", custom: true do
        assert {:error, :invalid_credentials, "Could not retrieve username from token"} =
                 ADFS.authorise(@config, %{
                   code: @code,
                   client_id: @client_id,
                   redirect_uri: @redirect_uri
                 })
      end
    end

    test "expired token from upstream" do
      use_cassette "adfs/authorise#7", custom: true do
        assert {:error, :invalid_credentials, "Failed to verify token claims (token expired?)"} =
                 ADFS.authorise(@config, %{
                   code: @code,
                   client_id: @client_id,
                   redirect_uri: @redirect_uri
                 })
      end
    end
  end

  describe "Fetch details" do
    test "Using a valid token" do
      assert {:ok, @name} = ADFS.get_name(@config, @token)
    end

    test "Using an invalid token" do
      assert {:error, _, _} = ADFS.get_name(@config, "Z")
    end
  end
end
