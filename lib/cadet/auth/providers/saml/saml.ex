defmodule Cadet.Auth.Providers.SAML do
  @moduledoc """
  Provides identity using SAML.
  """
  alias Cadet.Auth.Provider

  @behaviour Provider

  @type config :: %{assertion_extractor: module()}

  @spec authorise(config(), Provider.authorise_params()) ::
          {:ok, %{token: Provider.token(), username: String.t()}}
          | {:error, Provider.error(), String.t()}
  def authorise(config, %{
        conn: conn
      }) do
    %{assertion_extractor: assertion_extractor} = config

    with {:assertion, assertion} when not is_nil(assertion) <-
           {:assertion, Samly.get_active_assertion(conn)},
         {:name, name} when not is_nil(name) <- {:name, assertion_extractor.get_name(assertion)},
         {:username, username} when not is_nil(username) <-
           {:username, assertion_extractor.get_username(assertion)} do
      {:ok,
       %{
         token: Jason.encode!(%{name: name}),
         username: username
       }}
    else
      {:assertion, nil} -> {:error, :invalid_credentials, "Missing SAML assertion!"}
      {:name, nil} -> {:error, :invalid_credentials, "Missing name attribute!"}
      {:username, nil} -> {:error, :invalid_credentials, "Missing username attribute!"}
    end
  end

  @spec get_name(any(), Provider.token()) ::
          {:ok, String.t()} | {:error, Provider.error(), String.t()}
  def get_name(_config, token) do
    {:ok, Jason.decode!(token)["name"]}
  end
end

defmodule Cadet.Auth.Providers.AssertionExtractor do
  @moduledoc """
  A behaviour for modules that extract fields from SAML assertions.
  """
  @callback get_username(Samly.Assertion) :: String.t() | nil
  @callback get_name(Samly.Assertion) :: String.t() | nil
end
