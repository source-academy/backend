defmodule Cadet.Auth.Providers.OpenID do
  @moduledoc """
  Provides identity via an OpenID provider.
  """

  alias Cadet.Auth.Provider

  @behaviour Provider

  @type config :: %{openid_provider: atom(), claim_extractor: module()}

  @spec authorise(config(), Provider.authorise_params()) ::
          {:ok, %{token: Provider.token(), username: String.t()}}
          | {:error, Provider.error(), String.t()}
  def authorise(config, %{
        code: code,
        redirect_uri: redirect_uri
      }) do
    %{openid_provider: openid_provider, claim_extractor: claim_extractor} = config

    with {:token, {:ok, token_map}} <-
           {:token,
            OpenIDConnect.fetch_tokens(openid_provider, %{code: code, redirect_uri: redirect_uri})},
         {:get_token, token} when not is_nil(token) <-
           {:get_token, token_map[claim_extractor.get_token_type()]},
         {:verify_sig, {:ok, claims}} <-
           {:verify_sig, OpenIDConnect.verify(openid_provider, token)},
         {:verify_claims, {:ok, _}} <-
           {:verify_claims,
            Guardian.Token.Jwt.Verify.verify_claims(
              Cadet.Auth.EmptyGuardian,
              claims,
              nil
            )} do
      case claim_extractor.get_username(claims, token) do
        nil ->
          {:error, :invalid_credentials, "No username specified in token"}

        username ->
          {:ok,
           %{
             token: token,
             username: username
           }}
      end
    else
      {:token, {:error, _, _}} ->
        {:error, :invalid_credentials, "Failed to fetch token from OpenID provider"}

      {:get_token, nil} ->
        {:error, :invalid_credentials, "Missing token in response from OpenID provider"}

      {:verify_sig, {:error, _, _}} ->
        {:error, :invalid_credentials, "Failed to verify token"}

      {:verify_claims, {:error, _}} ->
        {:error, :invalid_credentials, "Failed to verify token claims (token expired?)"}
    end
  end

  # issue with JOSE's type specifications
  @dialyzer {:no_fail_call, [get_name: 2]}

  @spec get_name(config, Provider.token()) ::
          {:ok, String.t()} | {:error, Provider.error(), String.t()}
  def get_name(config, token) do
    %{claim_extractor: claim_extractor} = config
    # Assume the token has already been verified by authorise
    case claim_extractor.get_name(JOSE.JWT.peek(token).fields, token) do
      nil -> {:error, :invalid_credentials, "No name specified in token"}
      name -> {:ok, name}
    end
  end
end

defmodule Cadet.Auth.Providers.OpenID.ClaimExtractor do
  @moduledoc """
  A behaviour for modules that extract fields from JWT token claims.
  """
  @callback get_username(%{}, String.t()) :: String.t() | nil
  @callback get_name(%{}, String.t()) :: String.t() | nil
  @callback get_token_type() :: String.t() | nil
end
