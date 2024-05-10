defmodule Cadet.Auth.Providers.SAML do
  @moduledoc """
  Provides identity using SAML.
  """
  alias Cadet.Auth.Provider
  alias Samly.Assertion

  @behaviour Provider

  @type config :: %{assertion_extractor: module()}

  @spec authorise(
          any(),
          Provider.code() | Plug.Conn.t(),
          Provider.client_id(),
          Provider.redirect_uri()
        ) ::
          {:ok, %{token: Provider.token(), username: String.t()}}
          | {:error, Provider.error(), String.t()}
  def authorise(config, conn, _client_id, _redirect_uri) do
    %{assertion_extractor: assertion_extractor} = config

    with {:assertion, assertion} when not is_nil(assertion) <-
           {:assertion, Samly.get_attribute(conn)} do
      {:ok,
       %{
         token: Jason.encode!(%{name: assertion_extractor.get_name(assertion)}),
         username: assertion_extractor.get_username(assertion)
       }}
    else
      {:assertion, nil} -> {:error, :invalid_credentials, "Missing SAML assertion!"}
    end
  end

  @spec get_name(any(), Provider.token()) ::
          {:ok, String.t()} | {:error, Provider.error(), String.t()}
  def get_name(_config, token) do
    {:ok, Jason.decode!(token).name}
  end
end

defmodule Cadet.Auth.Providers.AssertionExtractor do
  @moduledoc """
  A behaviour for modules that extract fields from SAML assertions.
  """
  @callback get_username(Samly.Assertion) :: String.t() | nil
  @callback get_name(Samly.Assertion) :: String.t() | nil
end
