defmodule Cadet.Auth.Providers.SimpleSAML do
  @moduledoc """
  Provides identity using SimpleSAMLphp.
  """
  alias Cadet.Auth.Provider
  alias Samly.Assertion

  require Logger

  @behaviour Provider

  @type config :: %{idp_id: String.t()}

  @spec authorise(
          any(),
          Provider.code() | Plug.Conn.t(),
          Provider.client_id(),
          Provider.redirect_uri()
        ) ::
          {:ok, %{token: Provider.token(), username: String.t()}}
          | {:error, Provider.error(), String.t()}
  def authorise(config, conn, _client_id, _redirect_uri) do
    # Logger.debug("test")
    assertion = Samly.get_active_assertion(conn)
    IO.inspect(assertion)
    IO.inspect(assertion.attributes)
    # Logger.debug("assertion: #{inspect(assertion)}")
    expected_id = config.idp_id

    case get_assertion_idp_id(assertion) do
      nil ->
        {:error, :invalid_credentials, "Missing SAML assertion!"}

      ^expected_id ->
        # TODO: Add a assertion extractor to get the different fields
        {:ok,
         %{
           token: Map.get(assertion.attributes, "displayname"),
           username: Map.get(assertion.attributes, "samaccountname")
         }}

      _ ->
        {:error, :bad_request, "Invalid authentication provider"}
    end
  end

  @spec get_name(any(), Provider.token()) ::
          {:ok, String.t()} | {:error, Provider.error(), String.t()}
  def get_name(_config, token_as_name) do
    # case Enum.find(config, nil, fn %{token: this_token} -> token == this_token end) do
    #   %{name: name} -> {:ok, name}
    #   _ -> {:error, :invalid_credentials, "Invalid token"}
    # end
    {:ok, token_as_name}
  end

  defp get_assertion_idp_id(%Assertion{idp_id: idp_id}), do: idp_id
  defp get_assertion_idp_id(nil), do: nil
end
